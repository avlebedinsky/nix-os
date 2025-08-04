#!/usr/bin/env bash
# Скрипт для диагностики и исправления проблем с конфигурацией NixOS

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Диагностика конфигурации NixOS ===${NC}"

# Проверка версии NixOS
echo -e "${BLUE}1. Проверка версии NixOS:${NC}"
if command -v nixos-version &> /dev/null; then
    VERSION=$(nixos-version)
    echo "Версия: $VERSION"
    
    # Извлечение номера версии
    if [[ $VERSION =~ ([0-9]+\.[0-9]+) ]]; then
        VERSION_NUM="${BASH_REMATCH[1]}"
        echo "Номер версии: $VERSION_NUM"
        
        # Проверка совместимости
        if [[ $(echo "$VERSION_NUM >= 24.05" | bc -l) -eq 1 ]]; then
            echo -e "${GREEN}✓ Версия совместима с новой конфигурацией${NC}"
        else
            echo -e "${YELLOW}⚠ Версия может требовать старых опций конфигурации${NC}"
        fi
    fi
else
    echo -e "${RED}✗ Команда nixos-version не найдена${NC}"
fi

echo

# Проверка текущей конфигурации
echo -e "${BLUE}2. Проверка текущей конфигурации:${NC}"
CONFIG_FILE="/etc/nixos/configuration.nix"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "Файл конфигурации найден: $CONFIG_FILE"
    
    # Проверка на устаревшие опции
    echo -e "${BLUE}Проверка устаревших опций:${NC}"
    
    if grep -q "sound.enable" "$CONFIG_FILE"; then
        echo -e "${RED}✗ Найдена устаревшая опция: sound.enable${NC}"
        echo "  Строка: $(grep -n "sound.enable" "$CONFIG_FILE")"
    else
        echo -e "${GREEN}✓ sound.enable не найдена${NC}"
    fi
    
    if grep -q "hardware.opengl.driSupport" "$CONFIG_FILE"; then
        echo -e "${RED}✗ Найдена устаревшая опция: hardware.opengl.driSupport${NC}"
        echo "  Строка: $(grep -n "hardware.opengl.driSupport" "$CONFIG_FILE")"
    else
        echo -e "${GREEN}✓ hardware.opengl.driSupport не найдена${NC}"
    fi
    
    if grep -q "hardware.opengl" "$CONFIG_FILE"; then
        echo -e "${YELLOW}⚠ Найдена опция hardware.opengl (должна быть hardware.graphics)${NC}"
        echo "  Строка: $(grep -n "hardware.opengl" "$CONFIG_FILE")"
    else
        echo -e "${GREEN}✓ hardware.opengl не найдена${NC}"
    fi
    
else
    echo -e "${RED}✗ Файл конфигурации не найден: $CONFIG_FILE${NC}"
fi

echo

# Проверка синтаксиса
echo -e "${BLUE}3. Проверка синтаксиса конфигурации:${NC}"
if command -v nix-instantiate &> /dev/null; then
    if nix-instantiate --parse "$CONFIG_FILE" &> /dev/null; then
        echo -e "${GREEN}✓ Синтаксис конфигурации корректен${NC}"
    else
        echo -e "${RED}✗ Ошибка синтаксиса в конфигурации${NC}"
        echo "Подробности:"
        nix-instantiate --parse "$CONFIG_FILE" 2>&1 | head -10
    fi
else
    echo -e "${YELLOW}⚠ nix-instantiate не доступен${NC}"
fi

echo

# Предложения по исправлению
echo -e "${BLUE}4. Рекомендации:${NC}"

echo -e "${YELLOW}Для исправления проблем:${NC}"
echo "1. Создайте резервную копию текущей конфигурации:"
echo "   sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup"
echo
echo "2. Скопируйте исправленную конфигурацию:"
echo "   sudo cp configuration-clean.nix /etc/nixos/configuration.nix"
echo
echo "3. Попробуйте собрать конфигурацию без применения:"
echo "   sudo nixos-rebuild dry-build"
echo
echo "4. Если сборка успешна, примените изменения:"
echo "   sudo nixos-rebuild switch"
echo
echo "5. В случае проблем, откатитесь к предыдущей конфигурации:"
echo "   sudo nixos-rebuild switch --rollback"

echo
echo -e "${GREEN}=== Диагностика завершена ===${NC}"
