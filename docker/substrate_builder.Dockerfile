# This is the build stage for Substrate. Here we create the binary.
FROM docker.io/paritytech/ci-linux:production as builder

WORKDIR /substrate
COPY . /substrate
RUN cargo build --locked --release

# This is the 2nd stage: a very small image where we copy the Substrate binary."
FROM docker.io/library/alpine:3.17
LABEL description="Multistage Docker image for Substrate: a platform for web3" \
	io.parity.image.type="builder" \
	io.parity.image.authors="chevdor@gmail.com, devops-team@parity.io" \
	io.parity.image.vendor="Parity Technologies" \
	io.parity.image.description="Substrate is a next-generation framework for blockchain innovation 🚀" \
	io.parity.image.source="https://github.com/paritytech/substrate/blob/${VCS_REF}/docker/substrate_builder.Dockerfile" \
	io.parity.image.documentation="https://github.com/paritytech/substrate/blob/${VCS_REF}/docker/README.md"

COPY --from=builder /substrate/target/release/substrate /usr/local/bin
COPY --from=builder /substrate/target/release/subkey /usr/local/bin
COPY --from=builder /substrate/target/release/node-template /usr/local/bin
COPY --from=builder /substrate/target/release/chain-spec-builder /usr/local/bin

ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.34-r0

RUN apk update --no-cache && \
	apk add --no-cache git curl binutils && \
	curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
	curl -sLO "${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" && \
	curl -sLO "${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" && \
	apk add --force-overwrite --no-cache glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk && \
	addgroup --gid 1000 sgrp && \
	adduser -D -u 1000 -G sgrp -s /bin/sh -h /substrate -g "" susr sgrp && \
	mkdir -p /data /substrate/.local/share/substrate && \
	chown -R susr:sgrp /data && \
	ln -s /data /substrate/.local/share/substrate && \
# Sanity checks
	#ldd /usr/local/bin/substrate && \
# unclutter and minimize the attack surface
	rm -rf /usr/bin /usr/sbin && \
	rm -rf /var/cache/apk/* && \
	rm -rf /etc/apk/* && \
	/usr/local/bin/substrate --version

USER susr
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]
