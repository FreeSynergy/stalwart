# FreeSynergy packaging for Stalwart Mail Server
# Build: podman build -t ghcr.io/freesynergy/stalwart:latest .
FROM docker.io/library/rust:1-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential clang libclang-dev cmake libssl-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .
RUN cargo build --release \
    -p stalwart \
    --no-default-features \
    --features "sqlite s3"

FROM docker.io/library/debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/stalwart /usr/local/bin/stalwart

RUN useradd -r -s /bin/false stalwart && \
    mkdir -p /etc/stalwart /var/lib/stalwart && \
    chown -R stalwart:stalwart /etc/stalwart /var/lib/stalwart

VOLUME ["/etc/stalwart", "/var/lib/stalwart"]
EXPOSE 25 143 465 587 993 4190 8080

USER stalwart
ENTRYPOINT ["/usr/local/bin/stalwart"]
CMD ["--config", "/etc/stalwart/config.toml"]
