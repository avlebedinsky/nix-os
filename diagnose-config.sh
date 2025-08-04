#!/usr/bin/env bash
# Современный скрипт диагностики конфигурации NixOS и Hyprland

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции логирования
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Диагностика NixOS + Hyprland                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Проверка версии NixOS и совместимости
check_nixos_version() {
    log_info "=== ПРОВЕРКА ВЕРСИИ NIXOS ==="
    
    if command -v nixos-version &> /dev/null; then
        local version=$(nixos-version)
        log_success "Версия NixOS: $version"
        
        # Извлечение номера версии
        if [[ $version =~ ([0-9]+\.[0-9]+) ]]; then
            local version_num="${BASH_REMATCH[1]}"
            
            # Проверка совместимости без bc
            local major=$(echo $version_num | cut -d. -f1)
            local minor=$(echo $version_num | cut -d. -f2)
            
            if [[ $major -gt 24 ]] || [[ $major -eq 24 && $minor -ge 5 ]]; then
                log_success "Версия $version_num совместима с конфигурацией"
            else
                log_warning "Версия $version_num может требовать изменений в конфигурации"
            fi
        fi
    else
        log_error "nixos-version не найден"
        return 1
    fi
    
    return 0
}

# Проверка файлов конфигурации
check_config_files() {
    log_info "=== ПРОВЕРКА ФАЙЛОВ КОНФИГУРАЦИИ ==="
    
    local files=(
        "/etc/nixos/configuration.nix:Основная конфигурация NixOS"
        "/etc/nixos/hardware-configuration.nix:Конфигурация оборудования"
        "$HOME/.config/hypr/hyprland.conf:Конфигурация Hyprland"
        "$HOME/.config/waybar/config:Конфигурация Waybar"
        "$HOME/.config/waybar/style.css:Стили Waybar"
    )
    
    for file_info in "${files[@]}"; do
        local file_path=$(echo "$file_info" | cut -d: -f1)
        local description=$(echo "$file_info" | cut -d: -f2)
        
        if [[ -f "$file_path" ]]; then
            log_success "$description: $file_path"
        else
            log_warning "$description не найден: $file_path"
        fi
    done
    
    return 0
}

# Проверка среды виртуализации
check_virtualization() {
    log_info "=== ПРОВЕРКА СРЕДЫ ВИРТУАЛИЗАЦИИ ==="
    
    if command -v systemd-detect-virt &> /dev/null; then
        local virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
        
        case "$virt_type" in
            "oracle")
                log_success "VirtualBox обнаружен - используйте hyprland-virtualbox.conf"
                ;;
            "none")
                log_success "Физическое железо - используйте hyprland.conf"
                ;;
            *)
                log_info "Виртуализация: $virt_type"
                ;;
        esac
    else
        log_warning "systemd-detect-virt не найден"
    fi
    
    return 0
}

# Проверка сервисов
check_services() {
    log_info "=== ПРОВЕРКА СЕРВИСОВ ==="
    
    local services=(
        "pipewire:Аудио сервер"
        "NetworkManager:Сетевое управление"
        "hyprland:Оконный менеджер"
    )
    
    for service_info in "${services[@]}"; do
        local service=$(echo "$service_info" | cut -d: -f1)
        local description=$(echo "$service_info" | cut -d: -f2)
        
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_success "$description ($service) активен"
        elif systemctl --user is-active --quiet "$service" 2>/dev/null; then
            log_success "$description ($service) активен (пользователь)"
        else
            log_warning "$description ($service) не активен"
        fi
    done
    
    return 0
}

# Проверка пакетов
check_packages() {
    log_info "=== ПРОВЕРКА УСТАНОВЛЕННЫХ ПАКЕТОВ ==="
    
    local packages=(
        "hyprland:Оконный менеджер"
        "waybar:Панель"
        "kitty:Терминал"
        "rofi:Лаунчер"
        "firefox:Браузер"
        "thunar:Файловый менеджер"
    )
    
    for package_info in "${packages[@]}"; do
        local package=$(echo "$package_info" | cut -d: -f1)
        local description=$(echo "$package_info" | cut -d: -f2)
        
        if command -v "$package" &> /dev/null; then
            log_success "$description ($package) установлен"
        else
            log_warning "$description ($package) не найден"
        fi
    done
    
    return 0
}

# Проверка пользователей
check_users() {
    log_info "=== ПРОВЕРКА ПОЛЬЗОВАТЕЛЕЙ ==="
    
    if id "lav" &>/dev/null; then
        log_success "Пользователь 'lav' существует"
        
        # Проверка групп
        local groups=$(groups lav 2>/dev/null)
        if echo "$groups" | grep -q "wheel"; then
            log_success "Пользователь 'lav' в группе wheel (sudo доступ)"
        else
            log_warning "Пользователь 'lav' не в группе wheel"
        fi
        
        if echo "$groups" | grep -q "networkmanager"; then
            log_success "Пользователь 'lav' в группе networkmanager"
        else
            log_warning "Пользователь 'lav' не в группе networkmanager"
        fi
    else
        log_error "Пользователь 'lav' не существует"
    fi
    
    return 0
}

# Проверка синтаксиса конфигурации
check_config_syntax() {
    log_info "=== ПРОВЕРКА СИНТАКСИСА КОНФИГУРАЦИИ ==="
    
    if [[ -f "/etc/nixos/configuration.nix" ]]; then
        if nixos-rebuild dry-build &>/dev/null; then
            log_success "Синтаксис configuration.nix корректный"
        else
            log_error "Ошибки в configuration.nix"
            log_info "Запустите 'sudo nixos-rebuild dry-build' для деталей"
        fi
    else
        log_warning "configuration.nix не найден"
    fi
    
    return 0
}

# Генерация отчета
generate_report() {
    log_info "=== ОТЧЕТ И РЕКОМЕНДАЦИИ ==="
    
    echo -e "${YELLOW}📋 Рекомендации:${NC}"
    
    # Проверка на отсутствующие файлы
    if [[ ! -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        echo "• Запустите: sudo ./install-configs.sh"
    fi
    
    # Проверка пользователя
    if ! id "lav" &>/dev/null; then
        echo "• Примените конфигурацию: sudo nixos-rebuild switch"
    fi
    
    # Проверка VirtualBox
    local virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    if [[ "$virt_type" == "oracle" ]]; then
        echo "• VirtualBox: используйте hyprland-virtualbox.conf для лучшей производительности"
    fi
    
    echo
    echo -e "${BLUE}🔧 Полезные команды для диагностики:${NC}"
    echo "• journalctl -xe                    # Системные логи"
    echo "• systemctl --user status hyprland  # Статус Hyprland"
    echo "• pactl info                        # Информация об аудио"
    echo "• lspci | grep VGA                  # Информация о видеокарте"
    echo "• free -h                           # Использование памяти"
    echo "• df -h                             # Использование диска"
    
    return 0
}

# Главная функция
main() {
    local start_time=$(date +%s)
    
    check_nixos_version
    echo
    check_config_files
    echo
    check_virtualization
    echo
    check_services
    echo
    check_packages
    echo
    check_users
    echo
    check_config_syntax
    echo
    generate_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo
    echo -e "${GREEN}✅ Диагностика завершена за ${duration} секунд${NC}"
}

# Запуск
main "$@"
