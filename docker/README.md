# Substrate Builder Docker Image

The Docker image substrate_builder.Dockerfile in this folder is a `builder` image. It is self contained and allow users to build the binaries themselves.
There is no requirement on having Rust or any other toolchain installed but a working Docker environment.

Unlike the `parity/polkadot` image which contains a single binary (`polkadot`!) used by default, the image in this folder builds and contains several binaries and you need to provide the name of the binary to be called.

You should refer to the .Dockerfile for the actual list. At the time of editing, the list of included binaries is:

- substrate
- subkey
- node-template
- chain-spec-builder

The image can be used by passing the selected binary followed by the appropriate tags for this binary.

Your best guess to get started is to pass the `--help flag`. Here are a few examples:

- `docker run --rm -it parity/substrate substrate --version`
- `docker run --rm -it parity/substrate subkey --help`
- `docker run --rm -it parity/substrate node-template --version`
- `docker run --rm -it parity/substrate chain-spec-builder --help`

# Substrate Node Template Builder Docker Image

The Docker image substrate_node_template_builder.Dockerfile in this folder is also a `builder` image based upon substrate_builder.Dockerfile. It differs in that it **only** allows users to build the `node-template` binary.

The image can be used by passing the selected binary followed by the appropriate tags for this binary.

Refer to the Substrate Node Template [README](../bin/node-template/README.md) for usage instructions.