# Контракт между базовым образом и пакетным шаблоном

## Назначение

Определяет минимальные гарантии, которые базовый образ
(`docker/base/Dockerfile`) предоставляет пакетному шаблону
(`docker/package/Dockerfile.template`).

Изменения любого пункта контракта требуют пересборки **всех**
пакетных образов.

## Гарантии базового образа

| ENV / путь | Значение | Используется в package |
|------------|----------|------------------------|
| `ROS_DISTRO` | `humble` | `source /opt/ros/${ROS_DISTRO}/setup.bash` |
| `ROS2_USER` | `ros` | `COPY --chown=${ROS2_USER}:${ROS2_USER}`, `USER ${ROS2_USER}` |
| `ROS2_WS` | `/ros2_ws` | `WORKDIR`, `mkdir`, `chown` |
| `ROS2_INSTALL` | `/ros2_ws/install` | `COPY --from=builder`, `source` |
| Пользователь `${ROS2_USER}` | существует | `USER`, `COPY --chown` |
| Каталог `${ROS2_WS}` | существует, принадлежит `${ROS2_USER}` | `WORKDIR` |
| `libcudart` в `ldconfig -p` | присутствует | `HEALTHCHECK` |
| `/opt/ros/humble/setup.bash` | присутствует | `source` в package |

## Что НЕ гарантируется минимальным base

- PCL, OpenCV, Eigen, Boost, yaml-cpp — устанавливаются только в `*-slam` варианте.
- numpy/scipy — устанавливаются только в `*-slam` варианте.

Если пакету нужен SLAM-стек, в `config/packages.yaml` указывается
`base_variant: slam`.

## Варианты базовых образов

| Тег | Содержимое | Для чего |
|-----|------------|----------|
| `ros2-humble-cuda-base:amd64-minimal` | ROS2 + CUDA + tools | Произвольные ROS2-пакеты |
| `ros2-humble-cuda-base:amd64-slam` | minimal + SLAM-библиотеки | FAST-LIO2, FAST-LIVO2 |
| `ros2-humble-cuda-base:arm64-agx-cross-minimal` | То же для ARM64 | Cross QEMU |
| `ros2-humble-cuda-base:arm64-agx-cross-slam` | То же для ARM64 | Cross QEMU |
| `ros2-humble-cuda-base:arm64-agx-native` | l4t-jetpack + ROS2 + SLAM | Native Jetson (содержит всё) |

## Проверка контракта

```bash
# Проверить ENV в base-образе
docker run --rm <base-image> bash -c 'env | grep -E "^ROS2_|^ROS_DISTRO"'

# Проверить пользователя
docker run --rm <base-image> whoami   # ros

# Проверить каталог
docker run --rm <base-image> ls -ld /ros2_ws  # drwxr-xr-x ros ros

---

## 7. `.github/actions/docker-setup/action.yml`

```yaml
# ============================================================================
# Composite action: настройка Docker-окружения
# ============================================================================
# Устраняет дублирование шагов между build-base.yml и build-packages.yml.
#
# Что делает:
#   - Устанавливает REPO_SLUG (lowercase от github.repository) в $GITHUB_ENV
#   - Опционально включает QEMU (для cross-сборок ARM64)
#   - Устанавливает Buildx
#   - Логин в GHCR
#   - Опционально логин в NVIDIA NGC
# ============================================================================
name: 'Docker Setup'
description: 'Lowercase slug, QEMU, Buildx, GHCR/NGС login'

inputs:
  registry:
    description: 'Container registry'
    required: false
    default: 'ghcr.io'
  setup_qemu:
    description: 'Install QEMU for cross-build (true/false)'
    required: false
    default: 'true'
  ngc_login:
    description: 'Login to NVIDIA NGC (true/false)'
    required: false
    default: 'false'

runs:
  using: composite
  steps:
    - name: Set lowercase repository slug
      shell: bash
      run: |
        REPO_SLUG=$(echo '${{ github.repository }}' | tr '[:upper:]' '[:lower:]')
        echo "REPO_SLUG=${REPO_SLUG}" >> $GITHUB_ENV
        echo "Repo slug: ${REPO_SLUG}"

    - name: Set up QEMU
      if: inputs.setup_qemu == 'true'
      uses: docker/setup-qemu-action@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to GHCR
      uses: docker/login-action@v3
      with:
        registry: ${{ inputs.registry }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Log in to NVIDIA NGC
      if: inputs.ngc_login == 'true'
      uses: docker/login-action@v3
      with:
        registry: nvcr.io
        username: $oauthtoken
        password: ${{ secrets.NGC_API_KEY }}
