#!/usr/bin/env bash
# Быстрое исправление конфигурации NixOS

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Быстрое исправление конфигурации NixOS${NC}"

# Проверка прав доступа
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Этот скрипт должен быть запущен с правами root (sudo)${NC}"
    exit 1
fi

CONFIG_FILE="/etc/nixos/configuration.nix"
BACKUP_FILE="/etc/nixos/configuration.nix.backup.$(date +%Y%m%d-%H%M%S)"

# Создание резервной копии
echo -e "${YELLOW}Создание резервной копии...${NC}"
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Резервная копия создана: $BACKUP_FILE"
else
    echo -e "${RED}Файл конфигурации не найден: $CONFIG_FILE${NC}"
    exit 1
fi

# Исправление устаревших опций
echo -e "${YELLOW}Исправление устаревших опций...${NC}"

# Временный файл для исправленной конфигурации
TEMP_FILE=$(mktemp)

# Удаление sound.enable и исправление hardware.opengl
sed -e '/sound\.enable/d' \
    -e 's/hardware\.opengl/hardware.graphics/g' \
    -e 's/driSupport/enable32Bit/g' \
    -e '/driSupport32Bit/d' \
    "$CONFIG_FILE" > "$TEMP_FILE"

# Проверка изменений
if diff -q "$CONFIG_FILE" "$TEMP_FILE" > /dev/null; then
    echo -e "${GREEN}Конфигурация уже корректна, изменения не требуются${NC}"
    rm "$TEMP_FILE"
    exit 0
else
    echo -e "${YELLOW}Найдены изменения, применяем исправления...${NC}"
    mv "$TEMP_FILE" "$CONFIG_FILE"
    echo -e "${GREEN}Конфигурация исправлена${NC}"
fi

# Проверка синтаксиса
echo -e "${YELLOW}Проверка синтаксиса...${NC}"
if nix-instantiate --parse "$CONFIG_FILE" &> /dev/null; then
    echo -e "${GREEN}✓ Синтаксис корректен${NC}"
else
    echo -e "${RED}✗ Ошибка синтаксиса, восстанавливаем из резервной копии${NC}"
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    exit 1
fi

# Тестовая сборка
echo -e "${YELLOW}Выполнение тестовой сборки...${NC}"
if nixos-rebuild dry-build; then
    echo -e "${GREEN}✓ Тестовая сборка успешна${NC}"
    echo
    echo -e "${YELLOW}Теперь вы можете применить изменения:${NC}"
    echo "sudo nixos-rebuild switch"
else
    echo -e "${RED}✗ Ошибка при тестовой сборке${NC}"
    echo -e "${YELLOW}Восстанавливаем из резервной копии...${NC}"
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo "Попробуйте использовать configuration-clean.nix:"
    echo "sudo cp configuration-clean.nix /etc/nixos/configuration.nix"
fi

echo -e "${GREEN}Готово!${NC}"
