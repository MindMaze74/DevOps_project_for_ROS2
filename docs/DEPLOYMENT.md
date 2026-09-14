# Инструкция по развёртыванию

## Способы сборки

Реализованы **два способа** сборки ARM64-образов (ТЗ п. 3.4):

### Способ 1: Cross через QEMU (по умолчанию)

**Платформа:** GitHub-hosted runner (ubuntu-22.04).
**Base image:** `nvidia/cuda:12.8.2-devel-ubuntu22.04`.
**Тег:** `-cross`.

**Как работает:** QEMU эмулирует ARM64 при сборке. Готовый образ содержит настоящие ARM64-бинарники и запускается нативно на Jetson.

**Ограничения:**
- Не содержит L4T R36.5.0
- Не содержит Jetson-библиотек (TensorRT, VPI)
- ✅ CUDA 12.8 + ROS2 Humble + системные зависимости

### Способ 2: Native на self-hosted Jetson

**Платформа:** self-hosted runner на Jetson.
**Base image:** `nvcr.io/nvidia/l4t-jetpack:r36.4.0`.
**Тег:** `-native`.

**Как работает:** сборка нативно на реальном JetPack.

**Требования:**
- Jetson AGX Orin с JetPack 6.2.2
- Jetson Orin Nano с JetPack 7
- NGC_API_KEY в Secrets

## Регистрация Jetson как self-hosted runner

```bash
mkdir ~/actions-runner && cd ~/actions-runner
curl -o runner.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-arm64-2.320.0.tar.gz
tar xzf runner.tar.gz

./config.sh \
  --url https://github.com/MindMaze74/DevOps_project_for_ROS2 \
  --token <TOKEN> \
  --labels self-hosted,linux,arm64,jetson-agx \
  --name jetson-agx-orin

sudo ./svc.sh install && sudo ./svc.sh start