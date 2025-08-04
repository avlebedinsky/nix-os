# NixOS + Hyprland Configuration Installation

Простой скрипт для установки конфигураций NixOS и Hyprland.

## Что устанавливает скрипт

- **NixOS configuration** (`configuration.nix`) - основная системная конфигурация
- **Hyprland configuration** - конфигурация Wayland композитора
- **Waybar configuration** - панель задач для Hyprland
- **Kitty configuration** - терминал с правильными настройками кодировки

## Использование

```bash
# Простая установка (рекомендуется)
sudo ./install-configs.sh

# Показать справку
./install-configs.sh --help
```

## Важные замечания

### Hardware Configuration
Скрипт **НЕ изменяет** `hardware-configuration.nix`. Этот файл должен быть создан отдельно:

```bash
# Для генерации hardware-configuration.nix используйте:
sudo nixos-generate-config
```

### Первая установка NixOS
Если вы устанавливаете NixOS с нуля:

1. Установите базовую систему
2. Сгенерируйте hardware конфигурацию: `sudo nixos-generate-config`
3. Запустите этот скрипт для установки пользовательских конфигураций

## Структура проекта

```
.
├── install-configs.sh      # Основной скрипт установки
├── configuration.nix       # Системная конфигурация NixOS
├── hyprland.conf          # Конфигурация Hyprland
├── hyprland-virtualbox.conf # Оптимизированная для VirtualBox
├── waybar-config.json     # Конфигурация Waybar
├── waybar-style.css       # Стили Waybar
├── kitty.conf            # Конфигурация терминала Kitty
└── README.md             # Документация
```

## Особенности

- **Автоматическое определение VirtualBox** - использует оптимизированную конфигурацию Hyprland
- **Резервные копии** - создает backup всех изменяемых файлов
- **Проверка синтаксиса** - валидирует Nix конфигурации перед установкой
- **Исправление кодировки** - настраивает правильное отображение UTF-8

## Устранение проблем

### Отсутствует hardware-configuration.nix
```bash
sudo nixos-generate-config
```

### Проблемы с правами доступа
```bash
# Установка правильных прав
./set-permissions.sh
```

### Проверка конфигурации после установки
```bash
# Проверка синтаксиса
sudo nixos-rebuild dry-build

# Применение изменений
sudo nixos-rebuild switch
```
