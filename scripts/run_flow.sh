#!/bin/bash
set -e

# Portable OpenLane execution wrapper for RISC-V PicoRV32 Implementation
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

DESIGN_NAME="picorv32_custom"
RUN_TAG=${1:-run_reproduce}
EXTRA_ARGS="${@:2}"

PDK_ROOT=${PDK_ROOT:-$HOME/.ciel}
OPENLANE_ROOT=${OPENLANE_ROOT:-$HOME/OpenLane}
DOCKER_IMAGE="ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64"

echo "===================================================================="
echo " Starting Full-Flow ASIC Implementation (OpenLane / SkyWater 130nm)"
echo " Design:   ${DESIGN_NAME}"
echo " Run Tag:  ${RUN_TAG}"
echo " PDK Root: ${PDK_ROOT}"
echo "===================================================================="

# Ensure design directory is staged in OpenLane designs directory if available
if [ -d "${OPENLANE_ROOT}/designs" ]; then
    TARGET_DESIGN_DIR="${OPENLANE_ROOT}/designs/${DESIGN_NAME}"
    mkdir -p "${TARGET_DESIGN_DIR}/src"
    cp -r "${REPO_ROOT}/src/"* "${TARGET_DESIGN_DIR}/src/"
    cp "${REPO_ROOT}/config/config.tcl" "${TARGET_DESIGN_DIR}/config.tcl"
fi

# Run Flow container
docker run --rm \
    -v "${OPENLANE_ROOT}:/openlane" \
    -v "${OPENLANE_ROOT}/designs:/openlane/install" \
    -v "${HOME}:${HOME}" \
    -v "${PDK_ROOT}:${PDK_ROOT}" \
    -e PDK_ROOT="${PDK_ROOT}" \
    -e PDK=sky130A \
    --user $(id -u):$(id -g) \
    --network host \
    --security-opt seccomp=unconfined \
    "${DOCKER_IMAGE}" \
    sh -c "./flow.tcl -design ${DESIGN_NAME} -tag ${RUN_TAG} ${EXTRA_ARGS}"
