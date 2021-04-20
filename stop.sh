#!/bin/bash

function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-node.*.mychaincode.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-node.*.mychaincode.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

docker-compose -f docker-compose-cli.yaml -f docker-compose-etcdraft2.yaml down --volumes --remove-orphans

#Cleanup the chaincode containers
clearContainers
#Cleanup images
removeUnwantedImages

rm -rf channel-artifacts/*
rm -rf crypto-config/*
