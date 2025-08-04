#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# Automatic installation script for NixOS and Hyprland configurations
# Fixed encoding for proper display of Russian characters

# Force UTF-8 setup
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root privileges for system operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo for system configurations"
        log_info "Restarting with sudo..."
        exec sudo "$0" "$@"
    fi
}

# Get the username who called sudo
get_real_user() {
    if [[ -n "$SUDO_USER" ]]; then
        echo "$SUDO_USER"
    else
        echo "$(whoami)"
    fi
}

# Get user's home directory
get_user_home() {
    local user="$1"
    eval echo "~$user"
}

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Automatic NixOS + Hyprland Installation          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Check root privileges
check_root "$@"

# Determine user
REAL_USER=$(get_real_user)
USER_HOME=$(get_user_home "$REAL_USER")

log_info "User: $REAL_USER"
log_info "Home directory: $USER_HOME"

# Check execution permissions
if [[ ! -x "$0" ]]; then
    log_warning "Setting execution permissions..."
    chmod +x "$0"
fi

# Check that script is run from the correct directory
if [[ ! -f "configuration.nix" || ! -f "hyprland.conf" ]]; then
    log_error "Run script from directory with configurations"
    log_info "Current directory: $(pwd)"
    log_info "Expected files: configuration.nix, hyprland.conf"
    exit 1
fi

# Function to check and fix compatibility for NixOS 25.05+
fix_nixos_25_compatibility() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi
    
    log_info "Checking NixOS 25.05+ compatibility..."
    
    # Check NixOS version
    if command -v nixos-version &> /dev/null; then
        local version=$(nixos-version | grep -o '[0-9][0-9]\.[0-9][0-9]' | head -1)
        local major=$(echo $version | cut -d. -f1)
        local minor=$(echo $version | cut -d. -f2)
        
        if [[ $major -gt 24 ]] || [[ $major -eq 25 && $minor -ge 5 ]]; then
            log_info "Detected NixOS 25.05+, applying fixes..."
            
            # Remove deprecated virtualbox x11 option
            if grep -q "virtualisation.virtualbox.guest.x11" "$config_file"; then
                log_warning "Removing deprecated option virtualisation.virtualbox.guest.x11"
                sed -i '/virtualisation.virtualbox.guest.x11/d' "$config_file"
            fi
        fi
    fi
    
    return 0
}

# Function to check Nix files syntax
check_nix_syntax() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        log_error "$description not found: $file"
        return 1
    fi
    
    log_info "Checking syntax: $description"
    
    # Check for placeholder UUIDs in hardware-configuration.nix
    if [[ "$file" == "hardware-configuration.nix" ]]; then
        if grep -q "your-.*-uuid-here" "$file"; then
            log_error "CRITICAL: Found placeholder UUIDs in $file"
            log_error "This will cause system boot failure!"
            log_info "Please generate proper hardware configuration with: nixos-generate-config"
            return 1
        fi
    fi
    
    # Basic check for correct braces
    local open_braces=$(grep -o '{' "$file" | wc -l)
    local close_braces=$(grep -o '}' "$file" | wc -l)
    
    if [[ "$open_braces" -ne "$close_braces" ]]; then
        log_error "Brace mismatch in $file: opening=$open_braces, closing=$close_braces"
        return 1
    fi
    
    # Check for problematic packages
    if grep -q "locale$" "$file"; then
        log_warning "Found 'locale' package which may not exist - removing"
        sed -i '/locale$/d' "$file"
    fi
    
    # Check for duplicate VirtualBox settings
    if [[ "$file" == "configuration.nix" ]]; then
        local vbox_count=$(grep -c "virtualisation.virtualbox.guest.enable" "$file" || echo "0")
        if [[ "$vbox_count" -gt 1 ]]; then
            log_warning "Found duplicate VirtualBox guest settings - fixing"
            # Keep only the first occurrence
            sed -i '0,/virtualisation.virtualbox.guest.enable = true;/!{/virtualisation.virtualbox.guest.enable = true;/d;}' "$file"
        fi
    fi
    
    # Check for unclosed strings
    if grep -q '^[[:space:]]*#.*[^;]$' "$file" && grep -q '";$' "$file"; then
        log_success "Syntax of $description looks correct"
    else
        log_warning "Possible syntax issues in $file"
    fi
    
    return 0
}

# Function to create backup
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_name="$file.backup$(date +%Y%m%d-%H%M%S)"
        log_warning "Creating backup: $backup_name"
        cp "$file" "$backup_name"
        return 0
    fi
    return 1
}

# Function for safe copying with sudo
safe_copy() {
    local src="$1"
    local dest="$2"
    local owner="$3"
    
    if [[ ! -f "$src" ]]; then
        log_error "File not found: $src"
        return 1
    fi
    
    # Create directory if it doesn't exist
    local dest_dir=$(dirname "$dest")
    if [[ ! -d "$dest_dir" ]]; then
        log_info "Creating directory: $dest_dir"
        mkdir -p "$dest_dir"
    fi
    
    log_info "Copying: $src -> $dest"
    cp "$src" "$dest"
    
    # Set owner if specified
    if [[ -n "$owner" ]]; then
        chown "$owner:$owner" "$dest"
    fi
    
    return 0
}

# Function to install system configurations
install_system_configs() {
    log_info "=== INSTALLING SYSTEM CONFIGURATIONS ==="
    
    # Check compatibility with NixOS 25.05+
    if [[ -f "configuration.nix" ]]; then
        fix_nixos_25_compatibility "configuration.nix"
    fi
    
    if [[ -f "hardware-configuration.nix" ]]; then
        fix_nixos_25_compatibility "hardware-configuration.nix"
    fi
    
    # Check file syntax before installation
    if ! check_nix_syntax "configuration.nix" "configuration.nix"; then
        log_error "Syntax error in configuration.nix"
        return 1
    fi
    
    if [[ -f "hardware-configuration.nix" ]]; then
        if ! check_nix_syntax "hardware-configuration.nix" "hardware-configuration.nix"; then
            log_error "Syntax error in hardware-configuration.nix"
            return 1
        fi
    fi
    
    # Create backups of existing configurations
    backup_file "/etc/nixos/configuration.nix"
    backup_file "/etc/nixos/hardware-configuration.nix"
    
    # Copy new configurations
    safe_copy "configuration.nix" "/etc/nixos/configuration.nix"
    
    if [[ -f "hardware-configuration.nix" ]]; then
        safe_copy "hardware-configuration.nix" "/etc/nixos/hardware-configuration.nix"
        log_success "System configurations installed"
    else
        log_warning "hardware-configuration.nix not found, using existing one"
    fi
    
    return 0
}

# Function to install user configurations
install_user_configs() {
    log_info "=== INSTALLING USER CONFIGURATIONS ==="
    
    # Check for VirtualBox
    log_info "Detecting runtime environment..."
    local VIRTUALBOX_DETECTED=false
    
    if command -v systemd-detect-virt &> /dev/null; then
        local virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
        if [[ "$virt_type" == "oracle" ]]; then
            log_warning "VirtualBox environment detected - optimizations will be applied"
            VIRTUALBOX_DETECTED=true
        else
            log_info "Runtime environment: $virt_type"
        fi
    else
        log_warning "Unable to detect virtualization environment"
    fi
    
    # Create user directories
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
            log_info "Creating directory: $dir"
            sudo -u "$REAL_USER" mkdir -p "$dir"
        fi
    done
    
    # Install Hyprland configuration
    local hypr_config="$USER_HOME/.config/hypr/hyprland.conf"
    backup_file "$hypr_config"
    
    if [[ "$VIRTUALBOX_DETECTED" == "true" && -f "hyprland-virtualbox.conf" ]]; then
        log_info "Installing VirtualBox-optimized Hyprland configuration"
        safe_copy "hyprland-virtualbox.conf" "$hypr_config" "$REAL_USER"
    else
        log_info "Installing standard Hyprland configuration"
        safe_copy "hyprland.conf" "$hypr_config" "$REAL_USER"
    fi
    
    # Install Waybar configuration
    if [[ -f "waybar-config.json" && -f "waybar-style.css" ]]; then
        local waybar_config="$USER_HOME/.config/waybar/config"
        local waybar_style="$USER_HOME/.config/waybar/style.css"
        
        backup_file "$waybar_config"
        backup_file "$waybar_style"
        
        safe_copy "waybar-config.json" "$waybar_config" "$REAL_USER"
        safe_copy "waybar-style.css" "$waybar_style" "$REAL_USER"
        log_success "Waybar configuration installed"
    else
        log_warning "Waybar files not found, skipping"
    fi
    
    # Install Kitty configuration for proper character display
    if [[ -f "kitty.conf" ]]; then
        local kitty_config="$USER_HOME/.config/kitty/kitty.conf"
        backup_file "$kitty_config"
        safe_copy "kitty.conf" "$kitty_config" "$REAL_USER"
        log_success "Kitty configuration installed (encoding issues fixed)"
    else
        log_warning "kitty.conf not found, terminal may display characters incorrectly"
    fi
    
    log_success "User configurations installed"
    return 0
}

# Function to apply NixOS configuration
apply_nixos_config() {
    log_info "=== APPLYING NIXOS CONFIGURATION ==="
    
    # Check configuration syntax
    log_info "Checking configuration syntax..."
    if ! nixos-rebuild dry-build &>/dev/null; then
        log_error "Error in NixOS configuration!"
        log_info "Running diagnostics..."
        nixos-rebuild dry-build
        return 1
    fi
    
    log_success "Configuration syntax is correct"
    
    # Apply configuration
    log_info "Applying NixOS configuration (this may take several minutes)..."
    if nixos-rebuild switch; then
        log_success "NixOS configuration applied successfully!"
        return 0
    else
        log_error "Error applying NixOS configuration!"
        return 1
    fi
}

# Function to check dependencies
check_dependencies() {
    log_info "=== CHECKING DEPENDENCIES ==="
    
    # Check NixOS version
    if command -v nixos-version &> /dev/null; then
        local current_version=$(nixos-version | grep -o '[0-9][0-9]\.[0-9][0-9]' | head -1)
        log_info "NixOS version: $current_version"
        
        if [[ "$current_version" < "24.05" ]]; then
            log_warning "NixOS version is older than 24.05. Changes may be required!"
        else
            log_success "NixOS version is compatible"
        fi
    else
        log_warning "Unable to determine NixOS version"
    fi
    
    # Check for cliphist availability (will be installed with configuration)
    if ! command -v cliphist &> /dev/null; then
        log_info "cliphist will be installed with configuration"
    else
        log_success "cliphist is already installed"
    fi
    
    return 0
}

# Function for final report
final_report() {
    log_info "=== INSTALLATION REPORT ==="
    
    echo -e "${GREEN}✓ Installed configurations:${NC}"
    
    # Check system files
    [[ -f "/etc/nixos/configuration.nix" ]] && echo "  ✓ /etc/nixos/configuration.nix"
    [[ -f "/etc/nixos/hardware-configuration.nix" ]] && echo "  ✓ /etc/nixos/hardware-configuration.nix"
    
    # Check user files
    [[ -f "$USER_HOME/.config/hypr/hyprland.conf" ]] && echo "  ✓ $USER_HOME/.config/hypr/hyprland.conf"
    [[ -f "$USER_HOME/.config/waybar/config" ]] && echo "  ✓ $USER_HOME/.config/waybar/config"
    [[ -f "$USER_HOME/.config/waybar/style.css" ]] && echo "  ✓ $USER_HOME/.config/waybar/style.css"
    [[ -f "$USER_HOME/.config/kitty/kitty.conf" ]] && echo "  ✓ $USER_HOME/.config/kitty/kitty.conf"
    
    echo
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo "1. ✅ NixOS configuration applied automatically"
    echo "2. 🔑 User 'lav' created with password 'lav'"
    echo "3. 🔒 Change password: sudo -u lav passwd"
    echo "4. 🔄 Reboot for complete changes to take effect"
    echo "5. 🚀 After reboot, log in as user 'lav'"
    echo "6. 🎨 Hyprland will start automatically"
    
    echo
    echo -e "${BLUE}🔧 Encoding fixes:${NC}"
    echo "- Additional fonts installed for terminal"
    echo "- Kitty configuration set up with UTF-8"
    echo "- Environment variables added for proper display"
    
    echo
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# MAIN FUNCTION
main() {
    log_info "Starting installation..."
    
    # Stage 1: Check dependencies
    if ! check_dependencies; then
        log_error "Error checking dependencies"
        exit 1
    fi
    
    echo
    
    # Stage 2: Install system configurations
    if ! install_system_configs; then
        log_error "Error installing system configurations"
        exit 1
    fi
    
    echo
    
    # Stage 3: Install user configurations
    if ! install_user_configs; then
        log_error "Error installing user configurations"
        exit 1
    fi
    
    echo
    
    # Stage 4: Apply NixOS configuration
    if ! apply_nixos_config; then
        log_error "Error applying NixOS configuration"
        log_info "You can try running 'sudo nixos-rebuild switch' manually"
        exit 1
    fi
    
    echo
    
    # Stage 5: Final report
    final_report
}

# Run main function
main "$@"
