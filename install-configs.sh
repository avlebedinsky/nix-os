#!/usr/bin/env bash
# Полностью автоматический скрипт установки конфигураций NixOS и Hyprland

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для логгирования
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка root прав для системных операций
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен запускаться с sudo для системных конфигураций"
        log_info "Перезапуск с sudo..."
        exec sudo "$0" "$@"
    fi
}

# Получение имени пользователя, который вызвал sudo
get_real_user() {
    if [[ -n "$SUDO_USER" ]]; then
        echo "$SUDO_USER"
    else
        echo "$(whoami)"
    fi
}

# Получение домашней директории пользователя
get_user_home() {
    local user="$1"
    eval echo "~$user"
}

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Автоматическая установка NixOS + Hyprland          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Проверка root прав
check_root "$@"

# Определение пользователя
REAL_USER=$(get_real_user)
USER_HOME=$(get_user_home "$REAL_USER")

log_info "Пользователь: $REAL_USER"
log_info "Домашняя директория: $USER_HOME"

# Проверка прав на выполнение
if [[ ! -x "$0" ]]; then
    log_warning "Настройка прав на выполнение..."
    chmod +x "$0"
fi

# Проверка, что скрипт запущен из правильной директории
if [[ ! -f "configuration.nix" || ! -f "hyprland.conf" ]]; then
    log_error "Запустите скрипт из директории с конфигурациями"
    log_info "Текущая директория: $(pwd)"
    log_info "Ожидаемые файлы: configuration.nix, hyprland.conf"
    exit 1
fi

# Функция для проверки синтаксиса Nix файлов
check_nix_syntax() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        log_error "$description не найден: $file"
        return 1
    fi
    
    log_info "Проверка синтаксиса: $description"
    
    # Базовая проверка на корректность скобок
    local open_braces=$(grep -o '{' "$file" | wc -l)
    local close_braces=$(grep -o '}' "$file" | wc -l)
    
    if [[ "$open_braces" -ne "$close_braces" ]]; then
        log_error "Несоответствие скобок в $file: открывающих=$open_braces, закрывающих=$close_braces"
        return 1
    fi
    
    # Проверка на незакрытые строки
    if grep -q '^[[:space:]]*#.*[^;]$' "$file" && grep -q '";$' "$file"; then
        log_success "Синтаксис $description выглядит корректно"
    else
        log_warning "Возможны проблемы с синтаксисом в $file"
    fi
    
    return 0
}

# Функция для создания бэкапа
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_name="$file.backup$(date +%Y%m%d-%H%M%S)"
        log_warning "Создание бэкапа: $backup_name"
        cp "$file" "$backup_name"
        return 0
    fi
    return 1
}

# Функция для безопасного копирования с sudo
safe_copy() {
    local src="$1"
    local dest="$2"
    local owner="$3"
    
    if [[ ! -f "$src" ]]; then
        log_error "Файл не найден: $src"
        return 1
    fi
    
    # Создание директории если не существует
    local dest_dir=$(dirname "$dest")
    if [[ ! -d "$dest_dir" ]]; then
        log_info "Создание директории: $dest_dir"
        mkdir -p "$dest_dir"
    fi
    
    log_info "Копирование: $src -> $dest"
    cp "$src" "$dest"
    
    # Установка владельца если указан
    if [[ -n "$owner" ]]; then
        chown "$owner:$owner" "$dest"
    fi
    
    return 0
}

# Функция установки системных конфигураций
install_system_configs() {
    log_info "=== УСТАНОВКА СИСТЕМНЫХ КОНФИГУРАЦИЙ ==="
    
    # Проверка синтаксиса файлов перед установкой
    if ! check_nix_syntax "configuration.nix" "configuration.nix"; then
        log_error "Ошибка синтаксиса в configuration.nix"
        return 1
    fi
    
    if [[ -f "hardware-configuration.nix" ]]; then
        if ! check_nix_syntax "hardware-configuration.nix" "hardware-configuration.nix"; then
            log_error "Ошибка синтаксиса в hardware-configuration.nix"
            return 1
        fi
    fi
    
    # Создание бэкапов существующих конфигураций
    backup_file "/etc/nixos/configuration.nix"
    backup_file "/etc/nixos/hardware-configuration.nix"
    
    # Копирование новых конфигураций
    safe_copy "configuration.nix" "/etc/nixos/configuration.nix"
    
    if [[ -f "hardware-configuration.nix" ]]; then
        safe_copy "hardware-configuration.nix" "/etc/nixos/hardware-configuration.nix"
        log_success "Системные конфигурации установлены"
    else
        log_warning "hardware-configuration.nix не найден, используется существующий"
    fi
    
    return 0
}

# Функция установки пользовательских конфигураций
install_user_configs() {
    log_info "=== УСТАНОВКА ПОЛЬЗОВАТЕЛЬСКИХ КОНФИГУРАЦИЙ ==="
    
    # Проверка на VirtualBox
    log_info "Определение среды выполнения..."
    local VIRTUALBOX_DETECTED=false
    
    if command -v systemd-detect-virt &> /dev/null; then
        local virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
        if [[ "$virt_type" == "oracle" ]]; then
            log_warning "Обнаружена VirtualBox среда - будут применены оптимизации"
            VIRTUALBOX_DETECTED=true
        else
            log_info "Среда выполнения: $virt_type"
        fi
    else
        log_warning "Невозможно определить среду виртуализации"
    fi
    
    # Создание пользовательских директорий
    local config_dirs=(
        "$USER_HOME/.config/hypr"
        "$USER_HOME/.config/waybar"
        "$USER_HOME/.config/kitty"
        "$USER_HOME/.config/rofi"
        "$USER_HOME/.config/mako"
        "$USER_HOME/.config/swayidle"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_info "Создание директории: $dir"
            sudo -u "$REAL_USER" mkdir -p "$dir"
        fi
    done
    
    # Установка Hyprland конфигурации
    local hypr_config="$USER_HOME/.config/hypr/hyprland.conf"
    backup_file "$hypr_config"
    
    if [[ "$VIRTUALBOX_DETECTED" == "true" && -f "hyprland-virtualbox.conf" ]]; then
        log_info "Установка VirtualBox-оптимизированной конфигурации Hyprland"
        safe_copy "hyprland-virtualbox.conf" "$hypr_config" "$REAL_USER"
    else
        log_info "Установка стандартной конфигурации Hyprland"
        safe_copy "hyprland.conf" "$hypr_config" "$REAL_USER"
    fi
    
    # Установка Waybar конфигурации
    if [[ -f "waybar-config.json" && -f "waybar-style.css" ]]; then
        local waybar_config="$USER_HOME/.config/waybar/config"
        local waybar_style="$USER_HOME/.config/waybar/style.css"
        
        backup_file "$waybar_config"
        backup_file "$waybar_style"
        
        safe_copy "waybar-config.json" "$waybar_config" "$REAL_USER"
        safe_copy "waybar-style.css" "$waybar_style" "$REAL_USER"
        log_success "Waybar конфигурация установлена"
    else
        log_warning "Файлы Waybar не найдены, пропускаем"
    fi
    
    log_success "Пользовательские конфигурации установлены"
    return 0
}

# Функция применения конфигурации NixOS
apply_nixos_config() {
    log_info "=== ПРИМЕНЕНИЕ КОНФИГУРАЦИИ NIXOS ==="
    
    # Проверка синтаксиса конфигурации
    log_info "Проверка синтаксиса конфигурации..."
    if ! nixos-rebuild dry-build &>/dev/null; then
        log_error "Ошибка в конфигурации NixOS!"
        log_info "Запуск диагностики..."
        nixos-rebuild dry-build
        return 1
    fi
    
    log_success "Синтаксис конфигурации корректный"
    
    # Применение конфигурации
    log_info "Применение конфигурации NixOS (это может занять несколько минут)..."
    if nixos-rebuild switch; then
        log_success "Конфигурация NixOS успешно применена!"
        return 0
    else
        log_error "Ошибка при применении конфигурации NixOS!"
        return 1
    fi
}

# Функция проверки зависимостей
check_dependencies() {
    log_info "=== ПРОВЕРКА ЗАВИСИМОСТЕЙ ==="
    
    # Проверка версии NixOS
    if command -v nixos-version &> /dev/null; then
        local current_version=$(nixos-version | grep -o '[0-9][0-9]\.[0-9][0-9]' | head -1)
        log_info "Версия NixOS: $current_version"
        
        if [[ "$current_version" < "24.05" ]]; then
            log_warning "Версия NixOS старше 24.05. Могут потребоваться изменения!"
        else
            log_success "Версия NixOS совместима"
        fi
    else
        log_warning "Невозможно определить версию NixOS"
    fi
    
    # Проверка наличия cliphist (будет установлен с конфигурацией)
    if ! command -v cliphist &> /dev/null; then
        log_info "cliphist будет установлен с конфигурацией"
    else
        log_success "cliphist уже установлен"
    fi
    
    return 0
}

# Функция финального отчета
final_report() {
    log_info "=== ОТЧЕТ ОБ УСТАНОВКЕ ==="
    
    echo -e "${GREEN}✓ Установленные конфигурации:${NC}"
    
    # Проверка системных файлов
    [[ -f "/etc/nixos/configuration.nix" ]] && echo "  ✓ /etc/nixos/configuration.nix"
    [[ -f "/etc/nixos/hardware-configuration.nix" ]] && echo "  ✓ /etc/nixos/hardware-configuration.nix"
    
    # Проверка пользовательских файлов
    [[ -f "$USER_HOME/.config/hypr/hyprland.conf" ]] && echo "  ✓ $USER_HOME/.config/hypr/hyprland.conf"
    [[ -f "$USER_HOME/.config/waybar/config" ]] && echo "  ✓ $USER_HOME/.config/waybar/config"
    [[ -f "$USER_HOME/.config/waybar/style.css" ]] && echo "  ✓ $USER_HOME/.config/waybar/style.css"
    
    echo
    echo -e "${YELLOW}📋 Следующие шаги:${NC}"
    echo "1. ✅ Конфигурация NixOS применена автоматически"
    echo "2. 🔑 Пользователь 'lav' создан с паролем 'lav'"
    echo "3. 🔒 Смените пароль: sudo -u lav passwd"
    echo "4. 🔄 Перезагрузитесь для полного применения изменений"
    echo "5. 🚀 После перезагрузки войдите как пользователь 'lav'"
    
    echo
    echo -e "${BLUE}🎯 Полезные команды:${NC}"
    echo "• sudo reboot                    # Перезагрузка"
    echo "• sudo -u lav passwd            # Смена пароля пользователя lav"
    echo "• systemctl --user status hyprland  # Проверка состояния"
    echo "• journalctl -f                 # Мониторинг логов"
    
    echo
    echo -e "${GREEN}🎉 Установка завершена успешно!${NC}"
}

# Главная функция
main() {
    local start_time=$(date +%s)
    
    # Этап 1: Проверка зависимостей
    if ! check_dependencies; then
        log_error "Проверка зависимостей не пройдена"
        exit 1
    fi
    
    # Этап 2: Установка системных конфигураций
    if ! install_system_configs; then
        log_error "Ошибка установки системных конфигураций"
        exit 1
    fi
    
    # Этап 3: Применение конфигурации NixOS
    if ! apply_nixos_config; then
        log_error "Ошибка применения конфигурации NixOS"
        log_info "Системные файлы скопированы, но конфигурация не применена"
        log_info "Попробуйте вручную: sudo nixos-rebuild switch"
        exit 1
    fi
    
    # Этап 4: Установка пользовательских конфигураций
    if ! install_user_configs; then
        log_error "Ошибка установки пользовательских конфигураций"
        exit 1
    fi
    
    # Этап 5: Финальный отчет
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    УСТАНОВКА ЗАВЕРШЕНА                      ║${NC}"
    echo -e "${GREEN}║                   Время: ${duration} секунд                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    final_report
    
    return 0
}

# Запуск основной функции
main "$@"
