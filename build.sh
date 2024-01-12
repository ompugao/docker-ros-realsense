#!/bin/bash

DOCKER_BUILDKIT=1 docker build \
       -t iory/realsense-ros-docker:noetic \
       --add-host="archive.ubuntu.com:$(dig +short jp.archive.ubuntu.com | tail -1)" \
       .
