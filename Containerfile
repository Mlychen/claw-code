# syntax=docker/dockerfile:1

# ---- Builder stage ----
FROM rust:bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libssl-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV CARGO_TERM_COLOR=always
WORKDIR /workspace

# Copy workspace files first for layer caching
COPY rust/Cargo.toml rust/Cargo.lock rust/
COPY rust/crates/ rust/crates/

# Build the CLI in release mode
RUN cd rust && cargo build --release -p rusty-claude-cli

# ---- Runtime stage ----
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /workspace/rust/target/release/claw /usr/local/bin/claw

# Expose common auth/config env vars
ENV ANTHROPIC_API_KEY=""
ENV ANTHROPIC_AUTH_TOKEN=""
ENV ANTHROPIC_BASE_URL=""
ENV OPENAI_API_KEY=""
ENV OPENAI_BASE_URL=""

ENTRYPOINT ["claw"]
CMD []
