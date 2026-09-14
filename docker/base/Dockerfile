# ============================================================================
# Базовый Docker-образ: ROS2 Humble + CUDA (минимальный, без SLAM)
# ============================================================================
# Паттерны: Multi-Stage Build, Security Hardening (non-root), Health Check
#
# Контракт для downstream-образов (см. docker/CONTRACT.md):
#   ROS2_USER     = ros
#   ROS2_WS       = /ros2_ws
#   ROS2_INSTALL  = /ros2_ws/install
#   ROS_DISTRO    = humble
#
# SLAM-специфичные библиотеки (PCL, OpenCV, Eigen) вынесены в
# docker/base/slam.Dockerfile — собирается как отдельный слой поверх
# этого образа. Минимальная база их не содержит.
# ============================================================================

ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base

# --- Locale + базовые утилиты ---
# ИСПРАВЛЕНО: ENV LANG/LC_ALL устанавливаются ПОСЛЕ locale-gen (порядок слоёв)
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales curl gnupg2 lsb-release ca-certificates \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV ROS_DISTRO=humble
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# --- Репозиторий ROS2 (все архитектуры) ---
# Условие uname -m удалено: внутри QEMU на ARM64 uname возвращает aarch64,
# nvidia/cuda:*-ubuntu22.04 не содержит ROS2 репу, а повторное добавление
# репы в l4t-jetpack безопасно.
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
        http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/ros2.list

# --- ROS2 Humble + инструменты сборки ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop \
        python3-colcon-common-extensions python3-rosdep \
        python3-vcstool python3-pip \
        build-essential cmake git wget \
    && rm -rf /var/lib/apt/lists/*

# --- rosdep ---
# ИСПРАВЛЕНО: не глушим ошибки полностью, сохраняем лог для отладки
RUN rosdep init 2>&1 | tee /tmp/rosdep-init.log || true && \
    rosdep update --rosdistro ${ROS_DISTRO}

# --- Contract ENV: единый источник истины для downstream-образов ---
ENV ROS2_USER=ros
ENV ROS2_WS=/ros2_ws
ENV ROS2_INSTALL=/ros2_ws/install

# --- Security Hardening: non-root user ---
# Создаём каталог workspace, но БЕЗ подкаталога src —
# его создаёт package Dockerfile для своей сборки.
RUN groupadd -r ${ROS2_USER} && \
    useradd -r -g ${ROS2_USER} -m -s /bin/bash ${ROS2_USER} && \
    mkdir -p ${ROS2_WS} && \
    chown -R ${ROS2_USER}:${ROS2_USER} ${ROS2_WS}

WORKDIR ${ROS2_WS}
USER ${ROS2_USER}

# --- Health Check ---
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ldconfig -p | grep -q libcudart && echo "CUDA OK" || exit 1

CMD ["/bin/bash"]