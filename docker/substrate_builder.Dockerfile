ARG BUILD_ENV=${BUILD_ENV}

# ===========================================================
# This is the build stage for Substrate. Here we create the binary.
FROM docker.io/paritytech/ci-linux:production as build_

WORKDIR /substrate
COPY . /substrate
ARG NODE_DIR=${NODE_DIR}
RUN cd ${NODE_DIR} && CARGO_TARGET_DIR=/substrate/target cargo build --locked --release

# ===========================================================
# This is the 2nd stage: a very small image where we copy the Substrate binary."
FROM docker.io/library/ubuntu:20.04 as build_
LABEL description="Multistage Docker image for Substrate: a platform for web3" \
	io.parity.image.type="builder" \
	io.parity.image.authors="chevdor@gmail.com, devops-team@parity.io" \
	io.parity.image.vendor="Parity Technologies" \
	io.parity.image.description="Substrate is a next-generation framework for blockchain innovation 🚀" \
	io.parity.image.source="https://github.com/paritytech/polkadot/blob/${VCS_REF}/docker/substrate_builder.Dockerfile" \
	io.parity.image.documentation="https://github.com/paritytech/polkadot/"

COPY --from=build_ /substrate/target/release/substrate /usr/local/bin
COPY --from=build_ /substrate/target/release/subkey /usr/local/bin
COPY --from=build_ /substrate/target/release/node-template /usr/local/bin
COPY --from=build_ /substrate/target/release/chain-spec-builder /usr/local/bin

RUN useradd -m -u 1000 -U -s /bin/sh -d /substrate substrate && \
	mkdir -p /data /substrate/.local/share/substrate && \
	chown -R substrate:substrate /data && \
	ln -s /data /substrate/.local/share/substrate && \
# unclutter and minimize the attack surface
	rm -rf /usr/bin /usr/sbin && \
# Sanity checks
	ldd /usr/local/bin/substrate && \
	/usr/local/bin/substrate --version

USER substrate

# ===========================================================
FROM docker.io/library/ubuntu:20.04 as build_node_template

LABEL description="Multistage Docker image for Substrate Node Template" \
  image.type="builder" \
  image.authors="you@email.com" \
  image.vendor="Substrate Developer Hub" \
  image.description="Multistage Docker image for Substrate Node Template" \
  image.source="https://github.com/substrate-developer-hub/substrate-node-template" \
  image.documentation="https://github.com/substrate-developer-hub/substrate-node-template"

# Copy the node binary.
COPY --from=builder /node-template/target/release/node-template /usr/local/bin

RUN useradd -m -u 1000 -U -s /bin/sh -d /node-template node-dev && \
  mkdir -p /data /node-template/.local/share && \
  chown -R node-dev:node-dev /data && \
  ln -s /data /node-template/.local/share/node-template && \
  # unclutter and minimize the attack surface
  rm -rf /usr/bin /usr/sbin && \
  # sanity checks and check if executable works in this container
  ldd /usr/local/bin/node-template && \
  /usr/local/bin/node-template --version

USER node-dev
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/node-template"]

FROM build_${BUILD_ENV}

EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]
