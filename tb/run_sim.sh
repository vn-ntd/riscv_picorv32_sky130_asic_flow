#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
MODE=${1:-rtl}

echo "=========================================================="
echo " Running Verification Simulation for RISC-V PicoRV32"
echo " Mode: ${MODE}"
echo "=========================================================="

if command -v iverilog &> /dev/null; then
    if [ "$MODE" == "rtl" ]; then
        echo "[INFO] Compiling RTL simulation..."
        iverilog -o "${SCRIPT_DIR}/simv" \
            -s picorv32_tb \
            "${REPO_ROOT}/src/picorv32a.v" \
            "${SCRIPT_DIR}/picorv32_tb.v"
    elif [ "$MODE" == "gls" ]; then
        echo "[INFO] Compiling Gate-Level Simulation (GLS)..."
        PDK_ROOT=${PDK_ROOT:-$HOME/.ciel}
        STD_CELL_VERILOG="${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
        PRIMITIVES_VERILOG="${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
        
        if [ ! -f "$STD_CELL_VERILOG" ]; then
            echo "[ERROR] Sky130 standard cell verilog model not found at $STD_CELL_VERILOG"
            exit 1
        fi
        
        iverilog -o "${SCRIPT_DIR}/simv" \
            -DFUNCTIONAL -DUNIT_DELAY=#1 \
            -s picorv32_tb \
            "$PRIMITIVES_VERILOG" \
            "$STD_CELL_VERILOG" \
            "${REPO_ROOT}/results/picorv32.v" \
            "${SCRIPT_DIR}/picorv32_tb.v"
    fi
    
    echo "[INFO] Executing simulation binary..."
    vvp "${SCRIPT_DIR}/simv"
    rm -f "${SCRIPT_DIR}/simv"
else
    echo "iverilog not found in host PATH. Running inside OpenLane Docker container..."
    DOCKER_IMAGE="ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64"
    docker run --rm \
        -v "${REPO_ROOT}:/work" \
        -w /work/tb \
        "$DOCKER_IMAGE" \
        iverilog -o /tmp/simv -s picorv32_tb /work/src/picorv32a.v /work/tb/picorv32_tb.v && vvp /tmp/simv
fi
