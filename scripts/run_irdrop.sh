#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

echo "========================================================================"
echo " Executing Power Grid IR-Drop Analysis (OpenROAD / SkyWater 130nm)"
echo " Repository Root: ${REPO_ROOT}"
echo "========================================================================"

# PDK discovery (Volare default, Ciel, or environment)
PDK_ROOT=${PDK_ROOT:-$HOME/.volare}
[ ! -d "$PDK_ROOT/sky130A" ] && [ -d "$HOME/.ciel/sky130A" ] && PDK_ROOT="$HOME/.ciel"

if command -v openroad &> /dev/null; then
    echo "[INFO] Using host OpenROAD installation..."
    cd "${REPO_ROOT}"
    openroad scripts/irdrop.tcl
else
    echo "[INFO] OpenROAD not detected in host PATH. Running via OpenLane Docker container..."
    DOCKER_IMAGE="ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64"
    docker run --rm \
        -v "${REPO_ROOT}:/work" \
        -v "${PDK_ROOT}:${PDK_ROOT}" \
        -e PDK_ROOT="${PDK_ROOT}" \
        -w /work \
        "${DOCKER_IMAGE}" \
        openroad scripts/irdrop.tcl
fi

echo "[SUCCESS] Power Grid IR-Drop analysis finished."
