#!/usr/bin/env bash
# This script is meant to be run on Unix/Linux based systems
set -e

printf "*** Start Substrate node template ***\n"

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
PARENT_DIR=$(dirname "$SCRIPT_DIR")
mkdir -p "$PARENT_DIR/.local"
mkdir -p "$PARENT_DIR/.cargo/registry"

cd $(dirname ${BASH_SOURCE[0]})/..

printf "Searching for docker-compose executable...\n"
# docker/compose v1
if ! [ -x "$(command -v docker-compose)" ]; then
    printf "Skipping docker-compose since executable is not installed.\n"
else
    printf "Detected docker-compose executable.\n"
    # docker-compose down --remove-orphans
    # docker-compose run --rm --service-ports dev $@
    exit
fi

# docker/compose v2
if ! [ -x "$(command -v docker)" ]; then
    printf "Skipping docker since docker executable is not installed.\n"
else
    printf "Detected docker executable.\n"
    exit_code=$(docker compose version &> /dev/null && echo $?)
    if [ $exit_code == "0" ]; then
        printf "Detected docker compose subcommand.\n"
        # docker compose down --remove-orphans
        # docker compose run --rm --service-ports dev $@

        # frame="frame" && [ ! -f $frame ] && [ ! -L $frame ] && ln -s ../../$frame $frame
        # utils="utils" && [ ! -f $utils ] && [ ! -L $utils ] && ln -s ../../$utils $utils
        # client="client" && [ ! -f $client ] && [ ! -L $client ] && ln -s ../../$client $client
        # primitives="primitives" && [ ! -f $primitives ] && [ ! -L $primitives ] && ln -s ../../$primitives $primitives

        # ONBUILD https://stackoverflow.com/a/54245466/3208553

        DOCKER_BUILDKIT=0 docker compose -f ${PARENT_DIR}/docker-compose-custom.yml build
    else
        printf "Skipping docker since docker executable subcommand not supported.\n"
    fi
    exit
fi

printf "Error: Unable to detect docker compose installation."
