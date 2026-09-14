# Архитектура системы кросс-платформенной сборки

## Компоненты

### 1. Базовый образ
- ROS2 Humble + CUDA Toolkit + системные зависимости
- Multi-stage build, non-root user, healthcheck
- Три варианта: amd64, arm64-agx, arm64-nano

### 2. Шаблон пакета
- Универсальный Dockerfile.template
- Аргументы: URL, ветка, имя пакета, CUDA-архитектура
- Multi-stage: builder + final

### 3. CI/CD (GitHub Actions)
- Динамическая матрица: пакет × платформа × тип сборки
- Cross (QEMU на x86) + Native (self-hosted Jetson)
- Кеширование слоёв (type=gha)
- Trivy-сканирование уязвимостей

### 4. Конфигурация
- `config/packages.yaml` — единая точка управления
- Добавление пакета = 1 строка

## Поток сборки

1. Push в main → триггер пайплайна
2. Job setup читает packages.yaml → генерирует матрицу
3. Job build параллельно собирает комбинации
4. Каждый образ тестируется (CUDA + ROS2)
5. Trivy сканирует уязвимости
6. Образы публикуются в ghcr.io