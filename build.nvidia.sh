#!/bin/bash

DOCKER_BUILDKIT=1 docker build \
       -t iory/realsense-ros-docker:noetic-nvidiagl \
	   -f Dockerfile.nvidiagl \
       --add-host="archive.ubuntu.com:$(dig +short jp.archive.ubuntu.com | tail -1)" \
       .

