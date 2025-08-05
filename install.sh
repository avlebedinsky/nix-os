#!/usr/bin/env bash
# NixOS + Hyprland configuration installation script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with root privileges"
        log_info "Restarting with sudo..."
        exec sudo "$0" "$@"
    fi
}

# Get real user
get_real_user() {
    if [[ -n "$SUDO_USER" ]]; then
        echo "$SUDO_USER"
    else
        echo "$(whoami)"
    fi
}

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          NixOS + Hyprland Configuration Installation         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

# Determine user and home directory
REAL_USER=$(get_real_user)
USER_HOME=$(eval echo "~$REAL_USER")
CONFIG_DIR="$USER_HOME/.config"

log_info "User: $REAL_USER"
log_info "Home directory: $USER_HOME"

# Check for configuration files
if [[ ! -f "configuration.nix" ]]; then
    log_error "File configuration.nix not found in current directory"
    exit 1
fi

if [[ ! -f "hyprland.conf" ]]; then
    log_error "File hyprland.conf not found in current directory"
    exit 1
fi

# Create necessary directories
log_info "Creating configuration directories..."
mkdir -p "$CONFIG_DIR/hypr"
mkdir -p "$CONFIG_DIR/waybar"
mkdir -p "$CONFIG_DIR/kitty"
mkdir -p "$CONFIG_DIR/fish"

# Copy configuration.nix
log_info "Copying configuration.nix to /etc/nixos/"
if [[ -f "/etc/nixos/configuration.nix" ]]; then
    log_warning "Creating backup of existing configuration.nix"
    cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup.$(date +%Y%m%d_%H%M%S)
fi

cp configuration.nix /etc/nixos/
chown root:root /etc/nixos/configuration.nix
chmod 644 /etc/nixos/configuration.nix
log_success "configuration.nix copied"

# Copy Hyprland configuration
log_info "Copying Hyprland configuration..."
cp hyprland.conf "$CONFIG_DIR/hypr/"
chown $REAL_USER:users "$CONFIG_DIR/hypr/hyprland.conf"
chmod 644 "$CONFIG_DIR/hypr/hyprland.conf"
log_success "Hyprland configuration copied"

# Copy Waybar configuration
if [[ -f "waybar-config.json" ]]; then
    log_info "Copying Waybar configuration..."
    cp waybar-config.json "$CONFIG_DIR/waybar/config"
    chown $REAL_USER:users "$CONFIG_DIR/waybar/config"
    chmod 644 "$CONFIG_DIR/waybar/config"
    log_success "Waybar configuration copied"
fi

if [[ -f "waybar-style.css" ]]; then
    cp waybar-style.css "$CONFIG_DIR/waybar/style.css"
    chown $REAL_USER:users "$CONFIG_DIR/waybar/style.css"
    chmod 644 "$CONFIG_DIR/waybar/style.css"
    log_success "Waybar styles copied"
fi

# Copy Kitty configuration
if [[ -f "kitty.conf" ]]; then
    log_info "Copying Kitty configuration..."
    cp kitty.conf "$CONFIG_DIR/kitty/"
    chown $REAL_USER:users "$CONFIG_DIR/kitty/kitty.conf"
    chmod 644 "$CONFIG_DIR/kitty/kitty.conf"
    log_success "Kitty configuration copied"
fi

# Copy Fish configuration
if [[ -f "fish-config.fish" ]]; then
    log_info "Copying Fish shell configuration..."
    cp fish-config.fish "$CONFIG_DIR/fish/config.fish"
    chown $REAL_USER:users "$CONFIG_DIR/fish/config.fish"
    chmod 644 "$CONFIG_DIR/fish/config.fish"
    log_success "Fish configuration copied"
fi

# Copy Git configuration
if [[ -f "gitconfig" ]]; then
    log_info "Copying Git configuration..."
    cp gitconfig "$USER_HOME/.gitconfig"
    chown $REAL_USER:users "$USER_HOME/.gitconfig"
    chmod 644 "$USER_HOME/.gitconfig"
    log_success "Git configuration copied"
    log_warning "Don't forget to change name and email in ~/.gitconfig"
fi

# Copy Mako configuration
if [[ -f "mako-config.conf" ]]; then
    log_info "Copying Mako configuration..."
    mkdir -p "$CONFIG_DIR/mako"
    cp mako-config.conf "$CONFIG_DIR/mako/config"
    chown $REAL_USER:users "$CONFIG_DIR/mako/config"
    chmod 644 "$CONFIG_DIR/mako/config"
    log_success "Mako configuration copied"
fi

# Copy Swaylock configuration
if [[ -f "swaylock-config.conf" ]]; then
    log_info "Copying Swaylock configuration..."
    mkdir -p "$CONFIG_DIR/swaylock"
    cp swaylock-config.conf "$CONFIG_DIR/swaylock/config"
    chown $REAL_USER:users "$CONFIG_DIR/swaylock/config"
    chmod 644 "$CONFIG_DIR/swaylock/config"
    log_success "Swaylock configuration copied"
fi

# Copy Swayidle configuration
if [[ -f "swayidle-config.sh" ]]; then
    log_info "Copying Swayidle configuration..."
    mkdir -p "$CONFIG_DIR/swayidle"
    cp swayidle-config.sh "$CONFIG_DIR/swayidle/config.sh"
    chown $REAL_USER:users "$CONFIG_DIR/swayidle/config.sh"
    chmod 755 "$CONFIG_DIR/swayidle/config.sh"
    log_success "Swayidle configuration copied"
fi

# Set directory permissions
chown -R $REAL_USER:users "$CONFIG_DIR/hypr"
chown -R $REAL_USER:users "$CONFIG_DIR/waybar"
chown -R $REAL_USER:users "$CONFIG_DIR/kitty"
chown -R $REAL_USER:users "$CONFIG_DIR/fish"
chown -R $REAL_USER:users "$CONFIG_DIR/mako"
chown -R $REAL_USER:users "$CONFIG_DIR/swaylock"
chown -R $REAL_USER:users "$CONFIG_DIR/swayidle"

echo
log_success "All configuration files successfully installed!"
echo
log_info "Next steps:"
echo -e "${YELLOW}1.${NC} Rebuild system: ${GREEN}sudo nixos-rebuild switch${NC}"
echo -e "${YELLOW}2.${NC} Reboot system: ${GREEN}sudo reboot${NC}"
echo -e "${YELLOW}3.${NC} Select Hyprland as session when logging in"
echo
log_warning "Make sure you have hardware-configuration.nix in /etc/nixos/"
log_info "If not, generate it with: sudo nixos-generate-config"
