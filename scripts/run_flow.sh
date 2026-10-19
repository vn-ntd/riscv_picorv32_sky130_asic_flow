#!/bin/bash
set -e

# Portable OpenLane execution wrapper for RISC-V PicoRV32 Implementation
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

DESIGN_NAME="picorv32"
RUN_TAG=${1:-run_reproduce}
EXTRA_ARGS="${@:2}"

# PDK discovery (Volare default or Ciel)
PDK_ROOT=${PDK_ROOT:-$HOME/.volare}
[ ! -d "$PDK_ROOT/sky130A" ] && [ -d "$HOME/.ciel/sky130A" ] && PDK_ROOT="$HOME/.ciel"

DOCKER_IMAGE="ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64"

echo "===================================================================="
echo " Starting Full-Flow ASIC Implementation (OpenLane / SkyWater 130nm)"
echo " Design:    ${DESIGN_NAME}"
echo " Run Tag:   ${RUN_TAG}"
echo " Repo Root: ${REPO_ROOT}"
echo " PDK Root:  ${PDK_ROOT}"
echo " Image:     ${DOCKER_IMAGE}"
echo "===================================================================="

if [ ! -d "${PDK_ROOT}/sky130A" ]; then
    echo "[WARNING] sky130A PDK was not detected at ${PDK_ROOT}."
    echo "[INFO] To install with volare run:"
    echo "       pip install volare"
    echo "       volare enable --pdk sky130 0fe599b2afb6708d281543108caf8310912f54af"
fi

# Run OpenLane directly via Docker container mounting repository as the design
docker run --rm \
    -v "${REPO_ROOT}:/openlane/designs/${DESIGN_NAME}" \
    -v "${PDK_ROOT}:${PDK_ROOT}" \
    -e PDK_ROOT="${PDK_ROOT}" \
    -e PDK=sky130A \
    --user $(id -u):$(id -g) \
    --network host \
    --security-opt seccomp=unconfined \
    "${DOCKER_IMAGE}" \
    flow.tcl -design "${DESIGN_NAME}" -tag "${RUN_TAG}" ${EXTRA_ARGS}
