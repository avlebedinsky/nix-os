#!/usr/bin/env bash
# Скрипт для установки конфигураций

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Установка конфигураций NixOS и Hyprland${NC}"

# Проверка прав на выполнение
if [[ ! -x "$0" ]]; then
    echo -e "${YELLOW}Настройка прав на выполнение...${NC}"
    chmod +x "$0"
fi

# Проверка, что скрипт запущен из правильной директории
if [[ ! -f "configuration.nix" || ! -f "hyprland.conf" ]]; then
    echo -e "${RED}Ошибка: Запустите скрипт из директории с конфигурациями${NC}"
    echo "Текущая директория: $(pwd)"
    echo "Ожидаемые файлы: configuration.nix, hyprland.conf"
    exit 1
fi

# Функция для создания бэкапа
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo -e "${YELLOW}Создание бэкапа: $file.backup$(date +%Y%m%d-%H%M%S)${NC}"
        cp "$file" "$file.backup$(date +%Y%m%d-%H%M%S)"
    fi
}

# Установка системных конфигураций NixOS
echo -e "${GREEN}1. Установка системных конфигураций...${NC}"

if [[ $EUID -eq 0 ]]; then
    echo "Копирование configuration.nix в /etc/nixos/"
    backup_file "/etc/nixos/configuration.nix"
    cp configuration.nix /etc/nixos/
    
    if [[ -f "hardware-configuration.nix" ]]; then
        echo "Копирование hardware-configuration.nix в /etc/nixos/"
        backup_file "/etc/nixos/hardware-configuration.nix"
        cp hardware-configuration.nix /etc/nixos/
    fi
else
    echo -e "${YELLOW}Для установки системных конфигураций запустите с sudo:${NC}"
    echo "sudo cp configuration.nix /etc/nixos/"
    echo "sudo cp hardware-configuration.nix /etc/nixos/"
fi

# Установка пользовательских конфигураций
echo -e "${GREEN}2. Установка пользовательских конфигураций...${NC}"

# Проверка на VirtualBox
echo "Проверка среды выполнения..."
if command -v systemd-detect-virt &> /dev/null; then
    virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    if [[ "$virt_type" == "oracle" ]]; then
        echo -e "${YELLOW}Обнаружена VirtualBox среда${NC}"
        VIRTUALBOX_DETECTED=true
    else
        echo "Среда: $virt_type"
        VIRTUALBOX_DETECTED=false
    fi
else
    echo "Невозможно определить среду виртуализации"
    VIRTUALBOX_DETECTED=false
fi

# Hyprland
echo "Создание ~/.config/hypr/"
mkdir -p ~/.config/hypr
backup_file ~/.config/hypr/hyprland.conf

if [[ "$VIRTUALBOX_DETECTED" == "true" && -f "hyprland-virtualbox.conf" ]]; then
    echo -e "${YELLOW}Установка VirtualBox-оптимизированной конфигурации Hyprland${NC}"
    cp hyprland-virtualbox.conf ~/.config/hypr/hyprland.conf
else
    cp hyprland.conf ~/.config/hypr/
fi
echo -e "${GREEN}✓${NC} Hyprland конфигурация установлена"

# Waybar
if [[ -f "waybar-config.json" && -f "waybar-style.css" ]]; then
    echo "Создание ~/.config/waybar/"
    mkdir -p ~/.config/waybar
    backup_file ~/.config/waybar/config
    backup_file ~/.config/waybar/style.css
    cp waybar-config.json ~/.config/waybar/config
    cp waybar-style.css ~/.config/waybar/style.css
    echo -e "${GREEN}✓${NC} Waybar конфигурация установлена"
fi

# Создание дополнительных директорий для конфигураций
echo -e "${GREEN}3. Создание дополнительных директорий...${NC}"
mkdir -p ~/.config/{kitty,rofi,mako,swayidle}

# Проверка наличия cliphist в системе
echo -e "${GREEN}4. Проверка дополнительных зависимостей...${NC}"
if ! command -v cliphist &> /dev/null; then
    echo -e "${YELLOW}⚠️  cliphist не найден. Добавьте его в configuration.nix для работы буфера обмена${NC}"
fi

# Проверка версии NixOS
echo -e "${GREEN}5. Проверка совместимости...${NC}"
if command -v nixos-version &> /dev/null; then
    current_version=$(nixos-version | grep -o '[0-9][0-9]\.[0-9][0-9]')
    echo "Текущая версия NixOS: $current_version"
    if [[ "$current_version" < "24.05" ]]; then
        echo -e "${RED}⚠️  ВНИМАНИЕ: Версия NixOS старше 24.05. Могут потребоваться изменения в конфигурации!${NC}"
    fi
fi

echo -e "${GREEN}Установка завершена!${NC}"
echo
echo -e "${GREEN}✓ Установленные конфигурации:${NC}"
echo "  - NixOS: /etc/nixos/configuration.nix"
if [[ -f "/etc/nixos/hardware-configuration.nix" ]]; then
    echo "  - Hardware: /etc/nixos/hardware-configuration.nix"
fi
echo "  - Hyprland: ~/.config/hypr/hyprland.conf"
if [[ -f ~/.config/waybar/config ]]; then
    echo "  - Waybar: ~/.config/waybar/"
fi
echo
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Если копировали системные конфигурации, выполните: sudo nixos-rebuild switch"
echo "2. Пароль пользователя 'lav' уже установлен в конфигурации (пароль: lav)"
echo "3. Смените пароль после первого входа: passwd"
echo "4. Перезагрузитесь или запустите Hyprland"
echo
echo -e "${YELLOW}⚠️  ВАЖНО: Проверьте совместимость с вашей версией NixOS:${NC}"
echo "- Эта конфигурация предназначена для NixOS 24.05+"
echo "- Если у вас более старая версия, могут потребоваться изменения"
echo "- Проверьте версию: nixos-version"
echo
echo -e "${YELLOW}Дополнительные конфигурации можно добавить в:${NC}"
echo "- ~/.config/kitty/kitty.conf (терминал)"
echo "- ~/.config/rofi/config.rasi (лаунчер)"
echo "- ~/.config/mako/config (уведомления)"
echo
echo -e "${YELLOW}Рекомендуемые дополнительные пакеты для configuration.nix:${NC}"
echo "- cliphist (менеджер буфера обмена)"
echo "- hyprpaper или swww (обои)"
echo "- hypridle (управление бездействием)"
echo "- hyprlock (блокировка экрана)"
echo "- brightnessctl (управление яркостью)"
echo "- playerctl (управление медиа)"
