#!/usr/bin/env bash
# ============================================================================
# Верификация CUDA в Docker-образе
# ============================================================================
set -euo pipefail

IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image:tag>"
    exit 1
fi

echo "============================================"
echo " CUDA Verification: $IMAGE"
echo "============================================"

docker run --rm "$IMAGE" bash -c '
    echo "--- 1. CUDA Runtime Libraries ---"
    ldconfig -p | grep -E "libcudart|libcublas|libcufft" && echo "OK" || { echo "FAIL"; exit 1; }

    echo ""
    echo "--- 2. CUDA Toolkit (nvcc) ---"
    if command -v nvcc &>/dev/null; then
        nvcc --version
    else
        echo "nvcc not found (runtime-only)"
    fi

    echo ""
    echo "--- 3. CUDA Devices ---"
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi 2>/dev/null || echo "no GPU visible in CI"
    fi

    echo ""
    echo "=== CUDA VERIFICATION COMPLETE ==="
'