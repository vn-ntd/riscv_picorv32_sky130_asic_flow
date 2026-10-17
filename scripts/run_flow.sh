#!/bin/bash
DESIGN=${1:-picorv32_custom}
TAG=${2:-run_test}
EXTRA_ARGS="${@:3}"

docker run --rm \
  -v /home/dung/OpenLane:/openlane \
  -v /home/dung/OpenLane/designs:/openlane/install \
  -v /home/dung:/home/dung \
  -v /home/dung/.ciel:/home/dung/.ciel \
  -e PDK_ROOT=/home/dung/.ciel \
  -e PDK=sky130A \
  --user 1000:1000 \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --network host \
  --security-opt seccomp=unconfined \
  ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64 \
  sh -c "./flow.tcl -design $DESIGN -tag $TAG $EXTRA_ARGS"
