#!/usr/bin/env bash
# ============================================================================
# Локальная сборка Docker-образа пакета
# Использование: ./scripts/build-local.sh <package> <platform>
# ============================================================================
set -euo pipefail

PACKAGE="${1:-}"
PLATFORM="${2:-}"

if [ -z "$PACKAGE" ] || [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <package> <platform>"
    echo "  package : fast-lio2 | fast-livo2"
    echo "  platform: amd64 | arm64-agx | arm64-nano"
    exit 1
fi

REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-MindMaze74}"

case "$PLATFORM" in
    amd64)      DOCKER_PLATFORM="linux/amd64"; CUDA_ARCH="75" ;;
    arm64-agx)  DOCKER_PLATFORM="linux/arm64"; CUDA_ARCH="87" ;;
    arm64-nano) DOCKER_PLATFORM="linux/arm64"; CUDA_ARCH="72" ;;
    *) echo "Unknown platform: $PLATFORM"; exit 1 ;;
esac

if ! command -v yq &>/dev/null; then
    echo "ERROR: yq is required. Install: https://github.com/mikefarah/yq"
    exit 1
fi

GIT_URL=$(yq -r ".packages[] | select(.name == \"$PACKAGE\") | .git" config/packages.yaml)
BRANCH=$(yq -r ".packages[] | select(.name == \"$PACKAGE\") | .branch" config/packages.yaml)
CMAKE_ARGS=$(yq -r ".packages[] | select(.name == \"$PACKAGE\") | .cmake_args" config/packages.yaml)

if [ -z "$GIT_URL" ] || [ "$GIT_URL" = "null" ]; then
    echo "ERROR: Package '$PACKAGE' not found in config/packages.yaml"
    exit 1
fi

docker run --privileged --rm tonistiigi/binfmt --install arm64 2>/dev/null || true
docker buildx create --name local-builder --use 2>/dev/null || docker buildx use local-builder

echo "============================================"
echo " Building: $PACKAGE"
echo " Platform: $PLATFORM ($DOCKER_PLATFORM)"
echo " CUDA Arch: $CUDA_ARCH"
echo " Base: $REGISTRY/$OWNER/ros2-humble-cuda-base:$PLATFORM"
echo "============================================"

docker buildx build \
    --platform "$DOCKER_PLATFORM" \
    --build-arg BASE_IMAGE="$REGISTRY/$OWNER/ros2-humble-cuda-base:$PLATFORM" \
    --build-arg PACKAGE_GIT="$GIT_URL" \
    --build-arg PACKAGE_BRANCH="$BRANCH" \
    --build-arg PACKAGE_NAME="$PACKAGE" \
    --build-arg CMAKE_ARGS="$CMAKE_ARGS" \
    --build-arg CUDA_ARCHITECTURES="$CUDA_ARCH" \
    -t "$REGISTRY/$OWNER/ros2-package-$PACKAGE:$PLATFORM" \
    -f docker/package/Dockerfile.template \
    --load \
    .

echo ""
echo "=== BUILD SUCCESSFUL ==="
echo "Image: $REGISTRY/$OWNER/ros2-package-$PACKAGE:$PLATFORM"