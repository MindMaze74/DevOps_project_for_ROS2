# ============================================================================
# SLAM-расширение базового образа
# ============================================================================
# Наследуется от минимального base-образа (ros2-humble-cuda-base:<platform>-minimal)
# Добавляет: PCL, OpenCV, Eigen, Boost, yaml-cpp, numpy, scipy.
#
# Используется для пакетов с base_variant: slam в config/packages.yaml
# (например, FAST-LIO2, FAST-LIVO2).
# ============================================================================

ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS slam

# Переключаемся на root для установки системных пакетов
USER root

# --- Системные зависимости для SLAM ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        libeigen3-dev libboost-all-dev libpcl-dev \
        libopencv-dev libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Научные Python-библиотеки ---
RUN pip3 install --no-cache-dir numpy scipy

# --- Единая очистка (без дублирования apt-get clean) ---
RUN rm -rf /tmp/* /var/tmp/*

USER ${ROS2_USER}