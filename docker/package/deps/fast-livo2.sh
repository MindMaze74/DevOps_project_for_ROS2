#!/bin/bash
# ============================================================================
# Пакет-специфичные зависимости для FAST-LIVO2
# ============================================================================
# Устанавливает Sophus (с патчем под GCC 11+) и Vikit.
# Подключается через ARG PACKAGE_DEPS_SCRIPT в Dockerfile.template.
# ============================================================================
set -euo pipefail

echo "=== Installing Sophus (with GCC 11+ patch) ==="
git clone --depth 1 https://github.com/strasdat/Sophus.git /tmp/Sophus
cd /tmp/Sophus
git checkout a621ff2e
sed -i -E \
    -e 's/unit_complex_\.real\(\) = ([0-9.]+);/unit_complex_.real(\1);/' \
    -e 's/unit_complex_\.imag\(\) = ([0-9.]+);/unit_complex_.imag(\1);/' \
    /tmp/Sophus/sophus/so2.cpp
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF
make -j"$(nproc)"
make install
ldconfig

echo "=== Installing Vikit ==="
git clone --depth 1 https://github.com/ethz-asl/vikit.git /tmp/vikit
cd /tmp/vikit
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
make install

echo "=== FAST-LIVO2 deps installed successfully ==="