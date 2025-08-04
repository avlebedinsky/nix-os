#!/usr/bin/env bash
# Скрипт для исправления частых синтаксических ошибок в конфигурациях NixOS

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции логирования
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Исправление синтаксиса                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Функция проверки и исправления скобок
fix_braces() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        log_warning "$description не найден: $file"
        return 1
    fi
    
    log_info "Проверка скобок в $description..."
    
    local open_braces=$(grep -o '{' "$file" | wc -l)
    local close_braces=$(grep -o '}' "$file" | wc -l)
    
    if [[ "$open_braces" -gt "$close_braces" ]]; then
        local missing=$((open_braces - close_braces))
        log_warning "Отсутствует $missing закрывающих скобок в $file"
        
        # Создание бэкапа
        cp "$file" "$file.backup-$(date +%Y%m%d-%H%M%S)"
        
        # Добавление недостающих скобок
        for ((i=1; i<=missing; i++)); do
            echo "}" >> "$file"
        done
        
        log_success "Добавлено $missing закрывающих скобок в $file"
        return 0
    elif [[ "$close_braces" -gt "$open_braces" ]]; then
        local extra=$((close_braces - open_braces))
        log_error "Лишних $extra закрывающих скобок в $file"
        log_info "Проверьте файл вручную"
        return 1
    else
        log_success "Скобки в $description сбалансированы"
        return 0
    fi
}

# Функция проверки и исправления точек с запятой
fix_semicolons() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    log_info "Проверка точек с запятой в $description..."
    
    # Проверка на строки, которые должны заканчиваться точкой с запятой
    local missing_semicolons=$(grep -n '[^;{}\s]$' "$file" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | wc -l)
    
    if [[ "$missing_semicolons" -gt 0 ]]; then
        log_warning "Возможно отсутствуют точки с запятой в $file"
        log_info "Проверьте строки вручную"
    else
        log_success "Точки с запятой в $description выглядят корректно"
    fi
    
    return 0
}

# Основная функция исправления
fix_syntax_errors() {
    local files=(
        "configuration.nix:Конфигурация NixOS"
        "hardware-configuration.nix:Конфигурация оборудования"
    )
    
    for file_info in "${files[@]}"; do
        local file_path=$(echo "$file_info" | cut -d: -f1)
        local description=$(echo "$file_info" | cut -d: -f2)
        
        if [[ -f "$file_path" ]]; then
            echo
            log_info "=== Исправление $description ==="
            fix_braces "$file_path" "$description"
            fix_semicolons "$file_path" "$description"
        fi
    done
}

# Функция проверки результата
verify_fixes() {
    log_info "=== ПРОВЕРКА РЕЗУЛЬТАТОВ ==="
    
    if [[ -f "configuration.nix" ]]; then
        log_info "Проверка configuration.nix..."
        local open=$(grep -o '{' "configuration.nix" | wc -l)
        local close=$(grep -o '}' "configuration.nix" | wc -l)
        
        if [[ "$open" -eq "$close" ]]; then
            log_success "configuration.nix: скобки сбалансированы ($open:$close)"
        else
            log_error "configuration.nix: скобки не сбалансированы ($open:$close)"
        fi
    fi
    
    if [[ -f "hardware-configuration.nix" ]]; then
        log_info "Проверка hardware-configuration.nix..."
        local open=$(grep -o '{' "hardware-configuration.nix" | wc -l)
        local close=$(grep -o '}' "hardware-configuration.nix" | wc -l)
        
        if [[ "$open" -eq "$close" ]]; then
            log_success "hardware-configuration.nix: скобки сбалансированы ($open:$close)"
        else
            log_error "hardware-configuration.nix: скобки не сбалансированы ($open:$close)"
        fi
    fi
}

# Функция генерации отчета
generate_report() {
    echo
    log_info "=== ОТЧЕТ И РЕКОМЕНДАЦИИ ==="
    
    echo -e "${YELLOW}📋 Что было сделано:${NC}"
    echo "• Проверены и исправлены скобки в Nix файлах"
    echo "• Созданы бэкапы изменённых файлов"
    echo "• Проверен базовый синтаксис"
    
    echo
    echo -e "${BLUE}🔧 Следующие шаги:${NC}"
    echo "• Проверьте конфигурацию: sudo nixos-rebuild dry-build"
    echo "• Если ошибки остались, проверьте файлы вручную"
    echo "• Запустите ./diagnose-config.sh для полной диагностики"
    
    echo
    echo -e "${GREEN}✅ Исправление синтаксиса завершено${NC}"
}

# Главная функция
main() {
    # Проверка директории
    if [[ ! -f "configuration.nix" ]]; then
        log_error "Запустите скрипт из директории с конфигурациями"
        exit 1
    fi
    
    fix_syntax_errors
    echo
    verify_fixes
    generate_report
}

# Запуск
main "$@"
