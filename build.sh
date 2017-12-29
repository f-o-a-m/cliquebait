#!/bin/bash
set -e
set -x 

export IMAGE_NAME=${IMAGE_NAME:-"foamspace/cliquebait"}
export GETH_VERSION=${GETH_VERSION:-"v1.7.3"}

docker build --pull --build-arg GETH_VERSION=$GETH_VERSION -t $IMAGE_NAME:latest .
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$GETH_VERSION

# docker push $IMAGE_NAME:latest
# docker push $IMAGE_NAME:$GETH_VERSION

