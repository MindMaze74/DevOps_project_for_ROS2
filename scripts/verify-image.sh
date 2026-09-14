#!/usr/bin/env bash
# ============================================================================
# Комплексная верификация образа: CUDA + ROS2 + зависимости (15 проверок)
# Использование: ./scripts/verify-image.sh <image:tag>
# ============================================================================
set -euo pipefail

IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image:tag>"
    exit 1
fi

echo "============================================"
echo " COMPREHENSIVE IMAGE VERIFICATION"
echo " Image: $IMAGE"
echo "============================================"

docker run --rm "$IMAGE" bash -c '
    PASS=0; FAIL=0
    check() {
        local name="$1"; shift
        if "$@" &>/dev/null; then
            echo "  [PASS] $name"; PASS=$((PASS+1))
        else
            echo "  [FAIL] $name"; FAIL=$((FAIL+1))
        fi
    }

    echo ""; echo "=== 1. System ==="
    check "OS Ubuntu 22.04" grep -q "22.04" /etc/os-release
    check "Python 3" python3 --version
    check "CMake" cmake --version
    check "Git" git --version

    echo ""; echo "=== 2. CUDA ==="
    check "libcudart" bash -c "ldconfig -p | grep -q libcudart"
    check "libcublas" bash -c "ldconfig -p | grep -q libcublas"
    check "CUDA headers" test -f /usr/local/cuda/include/cuda.h

    echo ""; echo "=== 3. ROS2 ==="
    check "ROS2 setup.bash" test -f /opt/ros/humble/setup.bash
    check "colcon" which colcon
    check "ros2 CLI" bash -c "source /opt/ros/humble/setup.bash && ros2 --version"

    echo ""; echo "=== 4. Libraries ==="
    check "Eigen3" test -d /usr/include/eigen3
    check "PCL" bash -c "ldconfig -p | grep -q libpcl"
    check "OpenCV" bash -c "ldconfig -p | grep -q libopencv"

    echo ""; echo "=== 5. Workspace ==="
    [ -f /ros2_ws/install/setup.bash ] && check "Workspace install" test -f /ros2_ws/install/setup.bash

    echo ""; echo "═══════════════════════════════════════"
    echo "  RESULTS: PASS=$PASS  FAIL=$FAIL"
    [ $FAIL -gt 0 ] && { echo "  STATUS: FAILED"; exit 1; } || echo "  STATUS: ALL PASSED"
'