#!/bin/bash
CONTAINER=${1:-app}
SCRIPTDIR=$(dirname $0)
DOCKERCOMPOSEYML=./docker-compose.yml
cd $SCRIPTDIR
set -e

XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
xhost +local:
chmod a+r $XAUTH

touch .bash_history
docker compose --project-name realsense_robot_filter -f $DOCKERCOMPOSEYML up -d ${CONTAINER}
set +e
docker compose --project-name realsense_robot_filter -f $DOCKERCOMPOSEYML exec --workdir /workspace ${CONTAINER} bash


