FROM docker.io/library/debian:bullseye-slim

ARG DEBIAN_CODENAME=bullseye

ENV SHELL /bin/bash
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME /root

# config for wasm32-unknown-unknown & clang
COPY ./docker/utility/base-ci-linux-config /root/.cargo/config
COPY ./docker/utility/debian-llvm-clang.key /etc/apt/trusted.gpg.d/debian-llvm-clang.gpg

WORKDIR $HOME/substrate

ARG RUST_NIGHTLY="2023-05-23"

ENV RUSTUP_HOME=$HOME/rustup \
    CARGO_HOME=$HOME/cargo \
    PATH=$HOME/cargo/bin:$PATH \
	CC=clang-14 \
    CXX=clang-14 \
	PYENV_ROOT=$HOME/.pyenv \
	RUST_BACKTRACE=1

COPY . $HOME/substrate

# install tools and dependencies
RUN apt-get -y update --fix-missing && \
	apt-get -y upgrade && \
	apt-get install -y build-essential pkg-config libssl-dev llvm libudev-dev make cmake graphviz time rhash ca-certificates && \
	apt-get install -y python3 python3-pip lsof ruby ruby-bundler git-restore-mtime xz-utils zstd unzip gnupg protobuf-compiler && \
	apt-get install -y git curl wget jq vim fd-find && \
	# add clang 14 repo
    echo "deb http://apt.llvm.org/${DEBIAN_CODENAME}/ llvm-toolchain-${DEBIAN_CODENAME}-14 main" >> /etc/apt/sources.list.d/llvm-toolchain-${DEBIAN_CODENAME}-14.list && \
    echo "deb-src http://apt.llvm.org/${DEBIAN_CODENAME}/ llvm-toolchain-${DEBIAN_CODENAME}-14 main" >> /etc/apt/sources.list.d/llvm-toolchain-${DEBIAN_CODENAME}-14.list && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends \
        clang-14 lldb-14 lld-14 libclang-14-dev && \
	# install specific minio client version (2023-04-06)
    curl -L "https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2023-04-06T16-51-10Z" -o /usr/local/bin/mc && \
    chmod 755 /usr/local/bin/mc && \
	# set a link to clang
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang-14 100 && \
	# set a link to ldd
    update-alternatives --install /usr/bin/ld ld /usr/bin/ld.lld-14 100 && \
	# it may be necessary to remove Cargo.lock:
	# test -f $HOME/substrate/Cargo.lock && rm $HOME/substrate/Cargo.lock && \
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- --default-toolchain nightly -y && \
	# install `rust-src` component for ui test
	rustup component add rust-src rustfmt clippy && \
	# install wasm target into default (stable) toolchain
	rustup target add wasm32-unknown-unknown && \
	# install specific Rust nightly, default is stable, use minimum components
	rustup toolchain install "nightly-${RUST_NIGHTLY}" --profile minimal --component rustfmt && \
	rustup default "nightly-${RUST_NIGHTLY}" && \
	rustup override set "nightly-${RUST_NIGHTLY}" && \
	# install wasm target into nightly toolchain
	rustup target add wasm32-unknown-unknown --toolchain "nightly-${RUST_NIGHTLY}" && \
	. $HOME/cargo/env && \
	apt-get install -y clang libclang-dev && \
	# install cargo tools
	cargo install cargo-web wasm-pack cargo-deny cargo-spellcheck cargo-hack \
		mdbook mdbook-mermaid mdbook-linkcheck mdbook-graphviz mdbook-last-changed && \
	cargo install cargo-nextest --locked && \
	# diener 0.4.6 NOTE: before upgrading please test new version with companion build
	# example can be found here: https://github.com/paritytech/substrate/pull/12710
	cargo install diener --version 0.4.6 && \
	# wasm-bindgen-cli version should match the one pinned in substrate
	# https://github.com/paritytech/substrate/blob/master/bin/node/browser-testing/Cargo.toml#L15
	cargo install --version 0.2.73 wasm-bindgen-cli && \
	# install wasm-gc. It's useful for stripping slimming down wasm binaries (polkadot)
	cargo install wasm-gc && \
	# install cargo hfuzz and honggfuzz dependencies
	apt-get -y update && \
	apt-get install -y binutils-dev libunwind-dev libblocksruntime-dev && \
	cargo install honggfuzz && \
	# install sccache
    cargo install sccache && \
	cargo --version && \
	rustc --version && \
	rustup show && \
	# https://github.com/pyenv/pyenv#installation
	git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
	echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
	echo 'eval "$(pyenv init -)"' >> ~/.bashrc && \
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile && \
	echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile && \
	echo 'eval "$(pyenv init -)"' >> ~/.profile && \
	. ~/.bashrc && \
	. ~/.profile && \
	# install dependencies for pyenv
	apt-get install -y libbz2-dev libncurses5-dev libreadline-dev libffi-dev sqlite3 libsqlite3-dev && \
	pyenv install 3.11 && \
	pyenv versions && \
	pyenv global 3.11 && \
	pyenv local 3.11 && \
	pip install yq
	# && \
	# cargo build

EXPOSE 30333 9933 9944 9615

CMD tail -f /dev/null
