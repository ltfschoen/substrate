#!/bin/bash

trap "echo; exit" INT
trap "echo; exit" HUP

# pushd .

PARENT_DIR=$( echo $(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")") )
# generate .env file from .env.example if it does not exist
# https://stackoverflow.com/a/47677632/3208553
if [ -e .env ]
then
  echo ".env file exists"
else
  echo "generating .env file from .env.example since it does not exist";
  touch .env && cp .env.example .env;
fi

# assign fallback values for environment variables from .env.example incase
# not declared in .env file. alternative approach is `echo ${X:=$X_FALLBACK}`
source $PARENT_DIR/.env.example
source $PARENT_DIR/.env

printf "\n*** Started building Docker container."
printf "\n*** Please wait... \n***"

# Find the current version from Cargo.toml
VERSION=`grep "^version" ./bin/node-clawbird/node/Cargo.toml | egrep -o "([0-9\.]+)"`
GITUSER=ltfschoen
GITREPO=substrate

# Build the image
printf "\n*** Building ${GITUSER}-${GITREPO}:latest docker image, hang on!"

# https://stackoverflow.com/a/25554904/3208553
set +e
bash -e <<TRY
  DOCKER_BUILDKIT=1 docker build --platform linux/arm64 -f ${PARENT_DIR}/docker/substrate_clawbird_builder.Dockerfile -t ${GITUSER}-${GITREPO}:latest ./
TRY
if [ $? -ne 0 ]; then
  printf "\n*** Detected error running 'docker build'. Trying 'docker buildx' instead...\n"
  DOCKER_BUILDKIT=1 docker buildx build --platform linux/arm64 -f {PARENT_DIR}/docker/substrate_clawbird_builder.Dockerfile -t ${GITUSER}-${GITREPO}:latest ./
fi
docker tag ${GITUSER}-${GITREPO}:latest ${GITUSER}-${GITREPO}:v${VERSION}

# Show the list of available images for this repo
printf "\n*** Image is ready: \n"
docker images | grep ${GITREPO}

docker run -it -d \
  --platform linux/arm64 \
  --env-file "${PARENT_DIR}/.env" \
  --hostname ${GITUSER}-${GITREPO} \
  --name ${GITUSER}-${GITREPO} \
  --publish 0.0.0.0:30333:30333 \
  --publish 0.0.0.0:9933:9933 \
  --publish 0.0.0.0:9944:9944 \
  --publish 0.0.0.0:9615:9615 \
  --volume ${PARENT_DIR}:/root/substrate:rw \
  ${GITUSER}-${GITREPO}:latest
if [ $? -ne 0 ]; then
  kill "$PPID"; exit 1;
fi
CONTAINER_ID=$(docker ps -n=1 -q)
printf "\n*** Finished building Docker container ${CONTAINER_ID}.\n\n"

docker ps -a

printf "\n*** Entering shell of Docker container...\n"
docker exec -it ${GITUSER}-${GITREPO} /bin/bash
if [ $? -ne 0 ]; then
  kill "$PPID"; exit 1;
fi
