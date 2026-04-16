# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## Stack

- **Language:** Rust (edition 2021)
- **Binary:** `claw` — CLI agent harness
- **Workspace:** `rust/` with 9 crates

## Essential Commands

All Rust commands run from the `rust/` directory:

```bash
cd rust

# Build
cargo build --workspace

# Run the CLI
cargo run -p rusty-claude-cli -- [args]

# Format check
cargo fmt --all --check

# Lint (strict — warnings are errors in CI)
cargo clippy --workspace --all-targets -- -D warnings

# Run all tests
cargo test --workspace

# Run a single test file
cargo test -p <crate-name> --test <test_name>

# Run a single test function
cargo test -p <crate-name> <test_function_name>
```

## Workspace Architecture

```
rust/
├── Cargo.toml              # Workspace root (members = ["crates/*"])
└── crates/
    ├── api/                # Provider clients (Anthropic, xAI, OpenAI-compatible, DashScope)
    │                       #   SSE streaming, auth, request/response types, proxy support
    ├── commands/           # Slash command registry, parsing, help rendering, JSON/text output
    ├── compat-harness/     # TS manifest extraction for parity testing
    ├── mock-anthropic-service/  # Deterministic mock Anthropic API for local testing
    ├── plugins/            # Plugin metadata, install/enable/disable/update flows
    ├── runtime/            # Core: ConversationRuntime, config, sessions, permissions,
    │                       #   MCP lifecycle, system prompt assembly, usage tracking
    ├── rusty-claude-cli/   # Main CLI binary (`claw`): REPL, prompt, subcommands
    ├── telemetry/          # Session tracing and usage telemetry
    └── tools/              # Built-in tool execution: Bash, Read/Write/Edit, Grep, Glob,
                            #   WebSearch, WebFetch, Agent, Todo, Notebook, Skill, etc.
```

### Key crate dependencies

- `rusty-claude-cli` depends on: `runtime`, `commands`, `tools`, `telemetry`, `api`, `plugins`
- `runtime` depends on: `api`, `tools`, `commands`, `telemetry`, `plugins`
- `tools` depends on: `api` (for agent surfaces)
- `commands` is relatively standalone (registry + rendering)

### Entry point

The main binary entry point is `rust/crates/rusty-claude-cli/src/main.rs`. It bootstraps the runtime from `runtime` crate, handles CLI argument parsing, and dispatches to either REPL mode, one-shot prompt, or subcommands (status, sandbox, agents, mcp, skills, doctor, etc.).

## CI Pipeline

Four jobs run on push/PR to `main` (working directory: `rust/`):

1. **doc-source-of-truth** — Python script validates docs/branding consistency
2. **cargo fmt** — `cargo fmt --all --check`
3. **cargo test --workspace** — full test suite
4. **cargo clippy --workspace** — lint with pedantic warnings

All must pass for merges to `main`.

## Config & Settings

Runtime config loads in order (later overrides earlier):
1. `~/.claw.json`
2. `~/.config/claw/settings.json`
3. `<repo>/.claw.json`
4. `<repo>/.claw/settings.json`
5. `<repo>/.claw/settings.local.json`

Workspace-level shared defaults are in `.claude.json` at repo root.

## Provider Architecture

Three built-in provider backends, selected by model name prefix or ambient credentials:
- **Anthropic** — `claude-*` models → `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN`
- **xAI** — `grok-*` models → `XAI_API_KEY`
- **OpenAI-compatible** — fallback → `OPENAI_API_KEY` (also serves OpenRouter, Ollama)
- **DashScope** — `qwen/` or `qwen-*` prefix → `DASHSCOPE_API_KEY`

See `USAGE.md` for the full provider matrix and routing details.

## Testing

- Workspace tests live alongside source in each crate (`tests/` directories and inline `#[cfg(test)]` modules)
- `rusty-claude-cli/tests/` contains CLI harness tests (mock parity, output format, resume commands)
- `api/tests/` contains provider integration tests
- `runtime/tests/` contains integration tests
- The mock parity harness (`crates/mock-anthropic-service/`) provides deterministic Anthropic-compatible mock for end-to-end CLI testing

## Working Agreement

- Prefer small, reviewable changes
- Keep generated bootstrap files aligned with actual repo workflows
- Keep shared defaults in `.claude.json`; reserve `.claude/settings.local.json` for machine-local overrides
- Do not overwrite existing `CLAUDE.md` content automatically; update it intentionally when repo workflows change
- `unsafe_code` is forbidden at the workspace level
