#!/usr/bin/env bash

set -e
set -x

IMAGE_NAME=${IMAGE_NAME:-"foamspace/cliquebait"}

if [ -z "$GETH_VERSION" ]
then
  GETH_VERSION=$(curl -s https://api.github.com/repos/ethereum/go-ethereum/releases/latest | jq --raw-output .tag_name)
fi

docker build --pull --build-arg GETH_VERSION=$GETH_VERSION -t $IMAGE_NAME:$GETH_VERSION .
# docker tag $IMAGE_NAME:$GETH_VERSION $IMAGE_NAME:latest

# docker push $IMAGE_NAME:latest
# docker push $IMAGE_NAME:$GETH_VERSION
