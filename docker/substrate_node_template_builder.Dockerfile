# This is a base image to build node_template nodes.
# It is based on substrate_builder.Dockerfile
FROM docker.io/paritytech/ci-linux:production as builder

WORKDIR /node-template
COPY ./bin/node-template /node-template
COPY ./client /client
COPY ./frame /frame
COPY ./primitives /primitives
COPY ./utils /utils
# optionally use `--locked`
RUN cargo build --release

# This is the 2nd stage: a very small image where we copy the binary."
FROM docker.io/library/ubuntu:20.04
LABEL description="Multistage Docker image for Substrate Node Template" \
  image.type="builder" \
  image.authors="you@email.com" \
  image.vendor="Substrate Developer Hub" \
  image.description="Multistage Docker image for Substrate Node Template" \
  image.source="https://github.com/substrate-developer-hub/substrate-node-template" \
  image.documentation="https://github.com/substrate-developer-hub/substrate-node-template"

COPY --from=builder /node-template/target/release/node-template /usr/local/bin

RUN useradd -m -u 1000 -U -s /bin/sh -d /node-template node-dev && \
  mkdir -p /data /node-template/.local/share/node-template && \
  chown -R node-dev:node-dev /data && \
  ln -s /data /node-template/.local/share/node-template && \
  # sanity checks and check if executable works in this container
  ldd /usr/local/bin/node-template && \
  # unclutter and minimize the attack surface
  # rm -rf /usr/bin /usr/sbin && \
  /usr/local/bin/node-template --version

USER node-dev
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]
