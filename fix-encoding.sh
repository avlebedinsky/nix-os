#!/usr/bin/env bash
# Скрипт для исправления проблем с кодировкой и отображением символов

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Исправление проблем с кодировкой                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Получение текущего пользователя
if [[ -n "$SUDO_USER" ]]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    REAL_USER="$(whoami)"
    USER_HOME="$HOME"
fi

log_info "Пользователь: $REAL_USER"
log_info "Домашняя директория: $USER_HOME"

# Функция для проверки текущих настроек локали
check_locale() {
    log_info "=== ПРОВЕРКА ТЕКУЩИХ НАСТРОЕК ЛОКАЛИ ==="
    
    echo "Текущая локаль:"
    locale
    echo
    
    echo "Переменные окружения:"
    echo "LANG: ${LANG:-не установлено}"
    echo "LC_ALL: ${LC_ALL:-не установлено}"
    echo "TERM: ${TERM:-не установлено}"
    echo
    
    # Проверка поддержки UTF-8
    if locale -a | grep -q "en_US.utf8\|en_US.UTF-8"; then
        log_success "UTF-8 локаль доступна"
    else
        log_warning "UTF-8 локаль может быть недоступна"
    fi
}

# Функция для проверки шрифтов
check_fonts() {
    log_info "=== ПРОВЕРКА УСТАНОВЛЕННЫХ ШРИФТОВ ==="
    
    if command -v fc-list &> /dev/null; then
        echo "Доступные моноширинные шрифты:"
        fc-list : family | grep -i -E "(mono|jetbrains|fira|dejavu|noto)" | sort | uniq | head -10
        echo
        
        # Проверка конкретных шрифтов для терминала
        if fc-list | grep -q "JetBrains Mono"; then
            log_success "JetBrains Mono установлен"
        else
            log_warning "JetBrains Mono не найден"
        fi
        
        if fc-list | grep -q "Noto"; then
            log_success "Noto шрифты установлены"
        else
            log_warning "Noto шрифты не найдены"
        fi
    else
        log_warning "fontconfig не установлен"
    fi
}

# Функция для тестирования отображения символов
test_unicode() {
    log_info "=== ТЕСТ ОТОБРАЖЕНИЯ UNICODE СИМВОЛОВ ==="
    
    echo "Тестирование различных символов:"
    echo "1. Русские символы: Привет мир! АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
    echo "2. Box drawing: ┌─┐│ │└─┘┏━┓┃ ┃┗━┛"
    echo "3. Стрелки: ←↑→↓↖↗↘↙"
    echo "4. Математические: ±×÷≤≥≠∞∑∫√"
    echo "5. Специальные: ★☆♠♣♥♦©®™€"
    echo "6. Emoji: 🚀🔧📋✅❌⚠️"
    echo
    
    read -p "Все символы отображаются корректно? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        log_success "Символы отображаются корректно!"
        return 0
    else
        log_warning "Обнаружены проблемы с отображением символов"
        return 1
    fi
}

# Функция для создания временного профиля с правильными настройками
create_temp_profile() {
    log_info "=== СОЗДАНИЕ ВРЕМЕННОГО ПРОФИЛЯ ==="
    
    local temp_profile="/tmp/utf8_profile"
    cat > "$temp_profile" << 'EOF'
# Временные настройки для исправления кодировки
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

# Для Wayland
export XKB_DEFAULT_LAYOUT=us,ru
export XKB_DEFAULT_OPTIONS=grp:alt_shift_toggle

# Для терминалов
export TERMINAL=kitty
EOF

    log_success "Временный профиль создан: $temp_profile"
    log_info "Для применения выполните: source $temp_profile"
}

# Функция для исправления конфигурации пользователя
fix_user_config() {
    log_info "=== ИСПРАВЛЕНИЕ ПОЛЬЗОВАТЕЛЬСКИХ НАСТРОЕК ==="
    
    # Создание или обновление .bashrc
    local bashrc="$USER_HOME/.bashrc"
    if [[ -f "$bashrc" ]]; then
        # Удаление старых настроек локали если есть
        sed -i '/^export LANG=/d' "$bashrc"
        sed -i '/^export LC_ALL=/d' "$bashrc"
        sed -i '/^export TERM=/d' "$bashrc"
    fi
    
    # Добавление правильных настроек
    cat >> "$bashrc" << 'EOF'

# Настройки для правильного отображения символов
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
EOF

    log_success "Обновлен $bashrc"
    
    # Аналогично для .zshrc если используется zsh
    local zshrc="$USER_HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        sed -i '/^export LANG=/d' "$zshrc"
        sed -i '/^export LC_ALL=/d' "$zshrc"
        sed -i '/^export TERM=/d' "$zshrc"
        
        cat >> "$zshrc" << 'EOF'

# Настройки для правильного отображения символов
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
EOF
        log_success "Обновлен $zshrc"
    fi
}

# Функция для исправления конфигурации Kitty
fix_kitty_config() {
    log_info "=== ПРОВЕРКА КОНФИГУРАЦИИ KITTY ==="
    
    local kitty_dir="$USER_HOME/.config/kitty"
    local kitty_config="$kitty_dir/kitty.conf"
    
    # Создание директории если не существует
    if [[ ! -d "$kitty_dir" ]]; then
        sudo -u "$REAL_USER" mkdir -p "$kitty_dir"
        log_info "Создана директория: $kitty_dir"
    fi
    
    # Проверка существующей конфигурации
    if [[ -f "$kitty_config" ]]; then
        if grep -q "JetBrains Mono" "$kitty_config" && grep -q "UTF-8" "$kitty_config"; then
            log_success "Конфигурация Kitty уже настроена для UTF-8"
        else
            log_warning "Конфигурация Kitty требует обновления"
            if [[ -f "kitty.conf" ]]; then
                cp "$kitty_config" "$kitty_config.backup"
                cp "kitty.conf" "$kitty_config"
                chown "$REAL_USER:$REAL_USER" "$kitty_config"
                log_success "Конфигурация Kitty обновлена"
            fi
        fi
    else
        log_warning "Конфигурация Kitty не найдена"
        if [[ -f "kitty.conf" ]]; then
            cp "kitty.conf" "$kitty_config"
            chown "$REAL_USER:$REAL_USER" "$kitty_config"
            log_success "Конфигурация Kitty создана"
        fi
    fi
}

# Основная функция
main() {
    # Проверка прав
    if [[ $EUID -ne 0 ]]; then
        log_error "Запустите скрипт с sudo для системных изменений"
        exit 1
    fi
    
    check_locale
    echo
    check_fonts
    echo
    
    # Только если есть проблемы
    if ! test_unicode; then
        echo
        log_info "Применение исправлений..."
        create_temp_profile
        fix_user_config
        fix_kitty_config
        
        echo
        log_info "=== РЕКОМЕНДАЦИИ ==="
        echo "1. Перезапустите терминал или выполните: source ~/.bashrc"
        echo "2. Если используете Kitty, перезапустите его"
        echo "3. Проверьте, что в NixOS установлены правильные шрифты"
        echo "4. При необходимости выполните: sudo nixos-rebuild switch"
        
        echo
        log_warning "Если проблемы остались:"
        echo "- Проверьте настройки терминала"
        echo "- Убедитесь, что системные шрифты установлены"
        echo "- Перезагрузите систему"
    fi
    
    echo
    log_success "Диагностика завершена"
}

# Запуск
main "$@"
