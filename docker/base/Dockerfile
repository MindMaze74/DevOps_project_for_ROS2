# ============================================================================
# Базовый Docker-образ: ROS2 Humble + CUDA
# ============================================================================
# Паттерны: Multi-Stage Build, Security Hardening (non-root), Health Check
# ============================================================================

ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base

ENV ROS_DISTRO=humble
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# --- Locale + базовые утилиты ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales curl gnupg2 lsb-release ca-certificates \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# --- Репозиторий ROS2 (только x86_64) ---
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
            -o /usr/share/keyrings/ros-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) \
            signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
            http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
            > /etc/apt/sources.list.d/ros2.list; \
    fi

# --- ROS2 Humble + инструменты сборки ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop \
        python3-colcon-common-extensions python3-rosdep \
        python3-vcstool python3-pip \
        build-essential cmake git wget \
    && rm -rf /var/lib/apt/lists/*

RUN rosdep init 2>/dev/null || true && \
    rosdep update --rosdistro ${ROS_DISTRO}

# --- Системные зависимости для SLAM ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        libeigen3-dev libboost-all-dev libpcl-dev \
        libopencv-dev libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir numpy scipy
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --- Security Hardening: non-root user ---
RUN groupadd -r ros && useradd -r -g ros -m -s /bin/bash ros && \
    mkdir -p /ros2_ws/src && chown -R ros:ros /ros2_ws

WORKDIR /ros2_ws
USER ros

# --- Health Check ---
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ldconfig -p | grep -q libcudart && echo "CUDA OK" || exit 1

CMD ["/bin/bash"]