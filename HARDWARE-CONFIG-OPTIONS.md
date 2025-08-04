# Hardware Configuration Options

Скрипт установки `install-configs.sh` теперь поддерживает гибкие опции для работы с `hardware-configuration.nix`.

## Доступные опции

### 1. Стандартное поведение (по умолчанию)
```bash
./install-configs.sh
```
- Копирует `hardware-configuration.nix` из репозитория в `/etc/nixos/`
- Требует наличие файла в репозитории
- Подходит, если конфигурация создана для конкретного оборудования

### 2. Автоматическая генерация
```bash
./install-configs.sh --auto-hardware
```
- Автоматически генерирует `hardware-configuration.nix` для текущего оборудования
- Использует `nixos-generate-config` для определения аппаратной конфигурации  
- **Рекомендуется для VirtualBox или нового оборудования**
- Не требует наличие `hardware-configuration.nix` в репозитории
- При неудаче автодетекции создает fallback конфигурацию, которую нужно проверить

### 3. Пропуск копирования
```bash
./install-configs.sh --skip-hardware
```
- Пропускает копирование `hardware-configuration.nix`
- Использует существующий файл в `/etc/nixos/hardware-configuration.nix`
- Подходит, если система уже правильно настроена

## Когда использовать какую опцию

### `--auto-hardware` рекомендуется:
- При установке в VirtualBox
- На новом оборудовании
- Когда репозиторий создавался на другом компьютере
- При первой установке NixOS

### `--skip-hardware` подходит:
- Когда система уже работает корректно
- При обновлении только основной конфигурации
- Если `hardware-configuration.nix` был настроен вручную

### Стандартное поведение используйте:
- Когда репозиторий создан специально для вашего оборудования
- При переносе конфигурации между идентичными системами

## Справка
```bash
./install-configs.sh --help
```

## Примеры использования

### Установка в VirtualBox
```bash
sudo ./install-configs.sh --auto-hardware
```

### Обновление только пользовательских конфигураций
```bash
sudo ./install-configs.sh --skip-hardware
```

### Полная установка с репозиторной hardware конфигурацией
```bash
sudo ./install-configs.sh
```

## Устранение неисправностей

### Ошибка "nixos-generate-config failed"
Если автогенерация не удалась, скрипт автоматически создаст fallback конфигурацию:

1. **Для VirtualBox**: Создается оптимизированная конфигурация
2. **Для обычного ПК**: Создается базовая конфигурация

**Важно**: После создания fallback конфигурации проверьте:
```bash
# Проверьте доступные диски
lsblk

# Или используйте fdisk
sudo fdisk -l

# Отредактируйте конфигурацию при необходимости
sudo nano /etc/nixos/hardware-configuration.nix
```

### Ручная генерация hardware конфигурации
Если автоматические методы не работают:
```bash
# Попробуйте сгенерировать вручную
sudo nixos-generate-config

# Или только показать конфигурацию
sudo nixos-generate-config --show-hardware-config
```

### Проверка синтаксиса
Перед применением конфигурации:
```bash
# Проверка синтаксиса
sudo nix-instantiate --parse /etc/nixos/configuration.nix
sudo nix-instantiate --parse /etc/nixos/hardware-configuration.nix
```
