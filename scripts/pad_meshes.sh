#!/bin/bash

SCRIPTDIR=$(dirname $0)
MESHDIR=${1:-/catkin_ws/src/crigroup/osr_description/urdf/meshes}
PADDING=${2:-0.005}
for file in $(ls -1 $MESHDIR/*.stl); do 
	python3 pad_mesh.py --input_mesh $file --output_mesh $MESHDIR/$(basename $file .stl)_pad.stl --padding $PADDING
done

#TODO pad robotiq gripper
