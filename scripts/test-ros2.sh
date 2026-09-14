#!/usr/bin/env bash
# ============================================================================
# Верификация ROS2 и пакета в Docker-образе
# ============================================================================
set -euo pipefail

IMAGE="${1:-}"
PACKAGE="${2:-}"

if [ -z "$IMAGE" ] || [ -z "$PACKAGE" ]; then
    echo "Usage: $0 <image:tag> <package_name>"
    exit 1
fi

echo "============================================"
echo " ROS2 Verification: $IMAGE"
echo " Package: $PACKAGE"
echo "============================================"

docker run --rm "$IMAGE" bash -c "
    echo '--- 1. ROS2 Distribution ---'
    source /opt/ros/humble/setup.bash
    echo \"ROS_DISTRO=\$ROS_DISTRO\"
    ros2 --help > /dev/null 2>&1 && echo 'PASS: ros2 --help' || exit 1

    echo ''
    echo '--- 2. Package Registration ---'
    source /ros2_ws/install/setup.bash
    ros2 pkg list | grep -i '$PACKAGE' || { echo 'FAIL'; exit 1; }
    echo 'OK: package registered'

    echo ''
    echo '--- 3. Package Executables ---'
    ros2 pkg executables '$PACKAGE' || echo 'No executables found'

    echo ''
    echo '=== ROS2 VERIFICATION COMPLETE ==='
"