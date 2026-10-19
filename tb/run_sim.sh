#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

echo "=========================================================="
echo " Running RTL Simulation for RISC-V PicoRV32"
echo "=========================================================="

if command -v iverilog &> /dev/null; then
    iverilog -o "${SCRIPT_DIR}/simv" \
        -s picorv32_tb \
        "${REPO_ROOT}/src/picorv32a.v" \
        "${SCRIPT_DIR}/picorv32_tb.v"
    
    echo "Running simulation..."
    vvp "${SCRIPT_DIR}/simv"
    rm -f "${SCRIPT_DIR}/simv"
else
    echo "iverilog not found in host PATH. You can run this inside Docker container:"
    echo "docker run --rm -v ${REPO_ROOT}:/work -w /work/tb efabless/openlane:v0.2 ./run_sim.sh"
fi
