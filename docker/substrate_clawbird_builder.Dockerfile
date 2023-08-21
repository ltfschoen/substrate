FROM arm64v8/ubuntu:20.04
# FROM docker.io/library/ubuntu:23.04

ENV HOME /root
WORKDIR $HOME/substrate

ARG RUST_NIGHTLY="2023-05-23"

ENV RUSTUP_HOME=$HOME/rustup \
    CARGO_HOME=$HOME/cargo \
    PATH=$HOME/cargo/bin:$PATH \
	PYENV_ROOT=$HOME/.pyenv \
	RUST_BACKTRACE=1

COPY . $HOME/substrate

# install tools and dependencies
RUN apt-get -y update --fix-missing && \
	apt-get -y upgrade && \
	apt-get install -y build-essential pkg-config libssl-dev make cmake graphviz time rhash && \
	apt-get install -y python3 python3-pip lsof ruby ruby-bundler git-restore-mtime xz-utils zstd unzip gnupg protobuf-compiler && \
	apt-get install -y git curl wget jq vim && \
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
	# this is required to be able to install `cargo-spellcheck`
	apt-get install -y libclang-dev && \
	# install cargo tools
	# cargo-spellcheck
	cargo install cargo-web wasm-pack cargo-deny cargo-hack \
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
	cargo --version && \
	rustc --version && \
	rustup show && \
	# https://ggkbase-help.berkeley.edu/how-to/install-pyenv/
	git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile && \
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile && \
	echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bash_profile && \
	. ~/.bash_profile && \
	# install dependencies for pyenv
	apt-get install -y libbz2-dev libncurses5-dev libreadline-dev libffi-dev sqlite3 libsqlite3-dev && \
	pyenv install 3.11 && \
	pyenv versions && \
	pyenv global 3.11 && \
	pyenv local 3.11 && \
	pip install yq && \
	cargo build

EXPOSE 30333 9933 9944 9615

CMD tail -f /dev/null
