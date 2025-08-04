#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# Скрипт для тестирования кодировки и отображения символов

# Принудительная установка UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Тест кодировки UTF-8                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}[INFO]${NC} Проверяем отображение различных символов..."
echo

# Тест 1: Русские символы
echo -e "${YELLOW}1. Русские символы:${NC}"
echo "   Привет, мир! АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
echo "   абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
echo

# Тест 2: Box drawing символы
echo -e "${YELLOW}2. Box drawing символы:${NC}"
echo "   ┌─────┬─────┐"
echo "   │ Окно│ Окно│"
echo "   ├─────┼─────┤"
echo "   │ Окно│ Окно│"
echo "   └─────┴─────┘"
echo

# Тест 3: Стрелки и символы
echo -e "${YELLOW}3. Стрелки и специальные символы:${NC}"
echo "   ←↑→↓ ↖↗↘↙ ⇐⇑⇒⇓"
echo "   ★☆♠♣♥♦ ©®™ €£¥$"
echo

# Тест 4: Математические символы
echo -e "${YELLOW}4. Математические символы:${NC}"
echo "   ±×÷≤≥≠≈∞∑∫√π∂"
echo

# Тест 5: Powerline символы
echo -e "${YELLOW}5. Powerline символы (для терминала):${NC}"
echo "   "
echo

# Тест 6: Emoji (если поддерживается)
echo -e "${YELLOW}6. Emoji символы:${NC}"
echo "   🚀 🔧 📋 ✅ ❌ ⚠️  🎨 🖥️  💻"
echo

# Тест 7: Информация о локали
echo -e "${YELLOW}7. Информация о локали:${NC}"
echo "   LANG: ${LANG}"
echo "   LC_ALL: ${LC_ALL}"
echo "   TERM: ${TERM}"
echo

# Тест 8: Проверка кодировки файла
echo -e "${YELLOW}8. Проверка кодировки этого скрипта:${NC}"
if command -v file &> /dev/null; then
    file "$0"
else
    echo "   Команда 'file' недоступна"
fi
echo

# Интерактивный тест
echo -e "${BLUE}[ВОПРОС]${NC} Все символы отображаются корректно? (y/n)"
read -p "Ответ: " response

if [[ "$response" == "y" || "$response" == "Y" || "$response" == "д" || "$response" == "Д" ]]; then
    echo -e "${GREEN}[SUCCESS]${NC} Отлично! Кодировка работает корректно."
    echo -e "${GREEN}[INFO]${NC} Ваш терминал правильно отображает UTF-8 символы."
else
    echo -e "${RED}[ERROR]${NC} Обнаружены проблемы с отображением символов."
    echo
    echo -e "${YELLOW}Возможные решения:${NC}"
    echo "1. Запустите: sudo ./fix-encoding.sh"
    echo "2. Установите правильные шрифты: sudo ./install-configs.sh"
    echo "3. Перезапустите терминал"
    echo "4. Проверьте настройки терминала (шрифт, кодировка)"
    echo
    echo -e "${BLUE}Для Kitty terminal:${NC}"
    echo "- Убедитесь, что установлен JetBrains Mono шрифт"
    echo "- Проверьте ~/.config/kitty/kitty.conf"
    echo
    echo -e "${BLUE}Для других терминалов:${NC}"
    echo "- Установите кодировку UTF-8 в настройках"
    echo "- Выберите моноширинный шрифт с поддержкой Unicode"
fi

echo
echo -e "${BLUE}[INFO]${NC} Тест завершен."
