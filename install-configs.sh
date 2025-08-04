#!/usr/bin/env bash
# Скрипт для установки конфигураций

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Установка конфигураций NixOS и Hyprland${NC}"

# Проверка, что скрипт запущен из правильной директории
if [[ ! -f "configuration.nix" || ! -f "hyprland.conf" ]]; then
    echo -e "${RED}Ошибка: Запустите скрипт из директории с конфигурациями${NC}"
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

# Hyprland
echo "Создание ~/.config/hypr/"
mkdir -p ~/.config/hypr
backup_file ~/.config/hypr/hyprland.conf
cp hyprland.conf ~/.config/hypr/
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

echo -e "${GREEN}Установка завершена!${NC}"
echo
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Если копировали системные конфигурации, выполните: sudo nixos-rebuild switch"
echo "2. Установите пароль пользователя: sudo passwd ваш_пользователь"
echo "3. Перезагрузитесь или запустите Hyprland"
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
