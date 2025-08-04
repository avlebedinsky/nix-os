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

# Parse command line arguments
SKIP_HARDWARE_COPY=false
AUTO_GENERATE_HARDWARE=false
COPY_HARDWARE_FROM_REPO=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-hardware)
            SKIP_HARDWARE_COPY=true
            shift
            ;;
        --auto-hardware)
            AUTO_GENERATE_HARDWARE=true
            shift
            ;;
        --copy-hardware)
            COPY_HARDWARE_FROM_REPO=true
            shift
            ;;
        --help|-h)
            echo "NixOS + Hyprland Configuration Installation Script"
            echo
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Hardware Configuration Options:"
            echo "  --skip-hardware     Use existing /etc/nixos/hardware-configuration.nix"
            echo "                      (default behavior - no changes to hardware config)"
            echo
            echo "  --auto-hardware     Auto-generate hardware-configuration.nix using"
            echo "                      nixos-generate-config (recommended for new systems)"
            echo
            echo "  --copy-hardware     Copy hardware-configuration.nix from repository"
            echo "                      (use when config was created for your specific hardware)"
            echo
            echo "  --help, -h          Show this help message"
            echo
            echo "Examples:"
            echo "  $0                        # Install only configuration.nix and user configs"
            echo "  $0 --auto-hardware       # Auto-generate hardware config + install configs"
            echo "  $0 --copy-hardware       # Copy hardware config from repo + install configs"
            echo "  $0 --skip-hardware       # Same as default - explicitly use existing hardware config"
            echo
            echo "Note: By default, hardware-configuration.nix is left unchanged."
            echo "      Use --auto-hardware for VirtualBox or new hardware."
            echo "      Use --copy-hardware only if repository config matches your hardware."
            exit 0
            ;;
        *)
            log_warning "Unknown option: $1"
            shift
            ;;
    esac
done

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

# Additional information about hardware configuration options
if [[ "$AUTO_GENERATE_HARDWARE" != "true" && "$SKIP_HARDWARE_COPY" != "true" && "$COPY_HARDWARE_FROM_REPO" != "true" ]]; then
    log_info "Hardware configuration will be left unchanged (default behavior)"
    log_info "Available hardware options:"
    log_info "  $0 --auto-hardware    # Auto-generate hardware config"
    log_info "  $0 --copy-hardware    # Copy hardware config from repository"
    log_info "  $0 --skip-hardware    # Explicitly use existing hardware config"
elif [[ "$COPY_HARDWARE_FROM_REPO" == "true" && ! -f "hardware-configuration.nix" ]]; then
    log_error "hardware-configuration.nix not found in repository"
    log_info "Cannot use --copy-hardware without hardware-configuration.nix file"
    log_info "Use --auto-hardware to generate automatically instead"
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

# Function to diagnose hardware generation issues
diagnose_hardware_generation() {
    log_info "=== HARDWARE GENERATION DIAGNOSTICS ==="
    
    # Check NixOS environment
    if [[ -f /etc/NIXOS ]]; then
        log_success "Running on NixOS"
    else
        log_error "Not running on NixOS - this may be the problem"
        log_info "This script should be run on a NixOS system"
        return 1
    fi
    
    # Check nixos-generate-config availability
    if command -v nixos-generate-config &> /dev/null; then
        log_success "nixos-generate-config found: $(which nixos-generate-config)"
        
        # Test basic functionality
        log_info "Testing nixos-generate-config --help..."
        if nixos-generate-config --help &> /dev/null; then
            log_success "nixos-generate-config responds to --help"
        else
            log_error "nixos-generate-config --help failed"
        fi
    else
        log_error "nixos-generate-config not found"
        log_info "Searching in common locations..."
        find /run/current-system /nix -name "nixos-generate-config" 2>/dev/null | head -3
    fi
    
    # Check system permissions
    if [[ $EUID -eq 0 ]]; then
        log_success "Running as root"
    else
        log_warning "Not running as root - some hardware detection may fail"
    fi
    
    # Check /sys filesystem
    if [[ -d /sys/class/dmi ]]; then
        log_success "/sys/class/dmi exists"
    else
        log_warning "/sys/class/dmi missing - hardware detection may be limited"
    fi
    
    # Check for hardware files
    log_info "Hardware information files:"
    [[ -f /proc/cpuinfo ]] && log_success "/proc/cpuinfo exists" || log_warning "/proc/cpuinfo missing"
    [[ -f /proc/meminfo ]] && log_success "/proc/meminfo exists" || log_warning "/proc/meminfo missing"
    [[ -d /sys/block ]] && log_success "/sys/block exists" || log_warning "/sys/block missing"
    
    # Check filesystem state
    log_info "Current filesystem mounts:"
    mount | grep -E "^/dev" | head -5
    
    # Check for virtualization
    if command -v systemd-detect-virt &> /dev/null; then
        local virt=$(systemd-detect-virt 2>/dev/null || echo "none")
        log_info "Virtualization: $virt"
    fi
    
    return 0
}

# Function to create fallback hardware configuration
create_fallback_hardware_config() {
    local target_file="$1"
    log_warning "Creating fallback hardware configuration..."
    
    # Detect system information
    local is_virtualbox=false
    local is_vmware=false
    local is_qemu=false
    
    # Enhanced virtualization detection
    if command -v systemd-detect-virt &> /dev/null; then
        local virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
        case "$virt_type" in
            "oracle")
                is_virtualbox=true
                log_info "VirtualBox detected"
                ;;
            "vmware")
                is_vmware=true
                log_info "VMware detected"
                ;;
            "qemu"|"kvm")
                is_qemu=true
                log_info "QEMU/KVM detected"
                ;;
            *)
                log_info "Virtualization type: $virt_type"
                ;;
        esac
    fi
    
    # Additional detection methods
    if [[ -f /proc/cpuinfo ]]; then
        if grep -q "hypervisor" /proc/cpuinfo; then
            log_info "Hypervisor detected in /proc/cpuinfo"
        fi
    fi
    
    # Check for VirtualBox guest additions
    if command -v VBoxService &> /dev/null || [[ -d /opt/VBoxGuestAdditions* ]]; then
        is_virtualbox=true
        log_info "VirtualBox Guest Additions detected"
    fi
    
    # Use existing hardware-configuration.nix as template if available
    if [[ -f "hardware-configuration.nix" ]]; then
        log_info "Using repository hardware-configuration.nix as fallback template"
        cp "hardware-configuration.nix" "$target_file"
        chmod 644 "$target_file"
        log_success "Fallback configuration copied from repository"
        return 0
    fi
    
    # Analyze current system to create better fallback
    log_info "Analyzing current system for fallback configuration..."
    
    # Detect available kernel modules
    local kernel_modules=""
    if [[ -f /proc/modules ]]; then
        if grep -q "ata_piix" /proc/modules; then
            kernel_modules+="\"ata_piix\" "
        fi
        if grep -q "ahci" /proc/modules; then
            kernel_modules+="\"ahci\" "
        fi
        if grep -q "xhci_pci" /proc/modules; then
            kernel_modules+="\"xhci_pci\" "
        fi
        if grep -q "ehci_pci" /proc/modules; then
            kernel_modules+="\"ehci_pci\" "
        fi
        if grep -q "ohci_pci" /proc/modules; then
            kernel_modules+="\"ohci_pci\" "
        fi
        kernel_modules+="\"usb_storage\" \"sd_mod\" \"sr_mod\""
    else
        # Default fallback modules
        if [[ "$is_virtualbox" == "true" ]]; then
            kernel_modules="\"ata_piix\" \"ohci_pci\" \"ehci_pci\" \"ahci\" \"sd_mod\" \"sr_mod\""
        else
            kernel_modules="\"xhci_pci\" \"ehci_pci\" \"ahci\" \"usb_storage\" \"sd_mod\" \"sr_mod\""
        fi
    fi
    
    # Try to detect actual filesystem layout
    local root_device=""
    local boot_device=""
    local root_fstype="ext4"
    local boot_fstype="vfat"
    
    # Analyze current mounts
    if command -v findmnt &> /dev/null; then
        root_device=$(findmnt -n -o SOURCE / 2>/dev/null || echo "/dev/disk/by-label/nixos")
        boot_device=$(findmnt -n -o SOURCE /boot 2>/dev/null || echo "/dev/disk/by-label/boot")
        root_fstype=$(findmnt -n -o FSTYPE / 2>/dev/null || echo "ext4")
        boot_fstype=$(findmnt -n -o FSTYPE /boot 2>/dev/null || echo "vfat")
    else
        # Fallback to mount parsing
        local mount_info=$(mount | grep "on / " | head -1)
        if [[ -n "$mount_info" ]]; then
            root_device=$(echo "$mount_info" | awk '{print $1}')
            root_fstype=$(echo "$mount_info" | sed 's/.*type \([^ ]*\).*/\1/')
        fi
        
        mount_info=$(mount | grep "on /boot " | head -1)
        if [[ -n "$mount_info" ]]; then
            boot_device=$(echo "$mount_info" | awk '{print $1}')
            boot_fstype=$(echo "$mount_info" | sed 's/.*type \([^ ]*\).*/\1/')
        fi
    fi
    
    log_info "Detected root device: $root_device ($root_fstype)"
    log_info "Detected boot device: $boot_device ($boot_fstype)"
    
    # Create configuration based on detected environment
    local hw_config=""
    if [[ "$is_virtualbox" == "true" ]]; then
        hw_config="# Hardware configuration for VirtualBox (auto-generated fallback)
# Generated on $(date)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + \"/installer/scan/not-detected.nix\") ];

  # Boot configuration optimized for VirtualBox
  boot.initrd.availableKernelModules = [ $kernel_modules ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems (detected from current system)
  fileSystems.\"/\" = {
    device = \"$root_device\";
    fsType = \"$root_fstype\";
    options = [ \"defaults\" ];
  };

  fileSystems.\"/boot\" = {
    device = \"$boot_device\";
    fsType = \"$boot_fstype\";
    options = [ \"defaults\" ];
  };

  swapDevices = [ ];

  # VirtualBox Guest Additions
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault \"x86_64-linux\";
  powerManagement.cpuFreqGovernor = lib.mkDefault \"performance\";
}"
    else
        hw_config="# Hardware configuration (auto-generated fallback)
# Generated on $(date)
# IMPORTANT: Review and adjust this configuration for your hardware
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + \"/installer/scan/not-detected.nix\") ];

  # Generic boot configuration
  boot.initrd.availableKernelModules = [ $kernel_modules ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems (detected from current system)
  # REVIEW: Verify these paths match your actual setup
  fileSystems.\"/\" = {
    device = \"$root_device\";
    fsType = \"$root_fstype\";
    options = [ \"defaults\" ];
  };

  fileSystems.\"/boot\" = {
    device = \"$boot_device\";
    fsType = \"$boot_fstype\";
    options = [ \"defaults\" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault \"x86_64-linux\";
  powerManagement.cpuFreqGovernor = lib.mkDefault \"ondemand\";
}"
    fi
    
    # Write the configuration
    echo "$hw_config" > "$target_file"
    chmod 644 "$target_file"
    
    log_success "Intelligent fallback hardware configuration created"
    if [[ "$is_virtualbox" != "true" ]]; then
        log_warning "IMPORTANT: Review device paths in $target_file"
        log_warning "Run 'lsblk' to verify filesystem layout"
    fi
    
    return 0
}

# Function to automatically generate hardware configuration
generate_hardware_config() {
    local target_file="$1"
    log_info "Generating hardware configuration automatically..."
    
    # Check if we have the required permissions
    if [[ $EUID -ne 0 ]]; then
        log_error "Root privileges required for hardware configuration generation"
        return 1
    fi
    
    # Check if nixos-generate-config exists and is executable
    if ! command -v nixos-generate-config &> /dev/null; then
        log_error "nixos-generate-config not found in PATH"
        log_info "Current PATH: $PATH"
        log_info "Searching for nixos-generate-config..."
        find /nix /usr /bin -name "nixos-generate-config" 2>/dev/null | head -5
        return 1
    fi
    
    log_info "Found nixos-generate-config: $(which nixos-generate-config)"
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target_file")"
    
    # Method 1: Try --show-hardware-config first (most reliable)
    log_info "Method 1: Trying --show-hardware-config..."
    local hw_output=$(nixos-generate-config --show-hardware-config 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 && -n "$hw_output" ]]; then
        echo "$hw_output" > "$target_file"
        if [[ -s "$target_file" ]]; then
            chmod 644 "$target_file"
            log_success "Hardware configuration generated using --show-hardware-config"
            return 0
        else
            log_warning "Generated file is empty"
            rm -f "$target_file"
        fi
    else
        log_warning "Method 1 failed with exit code: $exit_code"
        log_info "Error output: $hw_output"
    fi
    
    # Method 2: Try direct generation to target location
    log_info "Method 2: Attempting direct generation to $(dirname "$target_file")..."
    local gen_output=$(nixos-generate-config --root / --dir "$(dirname "$target_file")" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 && -f "$target_file" ]]; then
        chmod 644 "$target_file"
        log_success "Hardware configuration generated directly"
        return 0
    else
        log_warning "Method 2 failed with exit code: $exit_code"
        log_info "Error output: $gen_output"
    fi
    
    # Method 3: Use temporary directory
    log_info "Method 3: Trying with temporary directory..."
    local temp_dir=$(mktemp -d)
    
    gen_output=$(nixos-generate-config --root / --dir "$temp_dir" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 && -f "$temp_dir/hardware-configuration.nix" ]]; then
        cp "$temp_dir/hardware-configuration.nix" "$target_file"
        chmod 644 "$target_file"
        log_success "Hardware configuration generated via temporary directory"
        rm -rf "$temp_dir"
        return 0
    else
        log_warning "Method 3 failed with exit code: $exit_code"
        log_info "Error output: $gen_output"
        if [[ -d "$temp_dir" ]]; then
            log_info "Temp directory contents: $(ls -la "$temp_dir" 2>/dev/null || echo 'empty')"
            rm -rf "$temp_dir"
        fi
    fi
    
    # Method 4: Check system state
    log_info "Method 4: Checking system state for manual generation..."
    log_info "Kernel version: $(uname -r)"
    log_info "Available block devices:"
    lsblk 2>/dev/null || log_warning "lsblk not available"
    
    log_info "Mount points:"
    mount | grep -E "^/dev" || log_warning "No mounted devices found"
    
    log_error "All automatic generation methods failed"
    log_info "Will attempt fallback configuration creation..."
    return 1
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
    if grep -q "locale$" "$file" 2>/dev/null; then
        log_warning "Found 'locale' package which may not exist - removing"
        if command -v sed &> /dev/null; then
            sed -i '/locale$/d' "$file" 2>/dev/null || {
                log_warning "Failed to remove locale package automatically"
            }
        fi
    fi
    
    # Check for duplicate VirtualBox settings
    if [[ "$file" == "configuration.nix" ]]; then
        local vbox_count=$(grep -c "virtualisation.virtualbox.guest.enable" "$file" 2>/dev/null || echo "0")
        # Ensure vbox_count is a valid number
        if ! [[ "$vbox_count" =~ ^[0-9]+$ ]]; then
            vbox_count=0
        fi
        if [[ "$vbox_count" -gt 1 ]]; then
            log_warning "Found duplicate VirtualBox guest settings - fixing"
            # Keep only the first occurrence - use a safer approach
            if command -v sed &> /dev/null; then
                # Create a temporary file for safer editing
                local temp_file=$(mktemp)
                awk '!seen && /virtualisation.virtualbox.guest.enable = true;/ {seen=1; print; next} 
                     !/virtualisation.virtualbox.guest.enable = true;/ {print}' "$file" > "$temp_file"
                if [[ -s "$temp_file" ]]; then
                    mv "$temp_file" "$file"
                    log_success "Removed duplicate VirtualBox settings"
                else
                    rm -f "$temp_file"
                    log_warning "Failed to fix duplicate VirtualBox settings"
                fi
            fi
        fi
    fi
    
    # Simple syntax check completion
    log_success "Syntax check completed for $description"
    
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
    
    # Handle hardware configuration based on options
    local hardware_handled=false
    
    if [[ "$AUTO_GENERATE_HARDWARE" == "true" ]]; then
        log_info "Auto-generating hardware configuration..."
        if generate_hardware_config "/etc/nixos/hardware-configuration.nix"; then
            hardware_handled=true
            log_success "Hardware configuration auto-generated"
        else
            log_warning "Auto-generation failed, running diagnostics..."
            diagnose_hardware_generation
            
            log_warning "Attempting fallback configuration creation..."
            if create_fallback_hardware_config "/etc/nixos/hardware-configuration.nix"; then
                hardware_handled=true
                log_success "Fallback hardware configuration created"
            else
                log_error "Failed to create hardware configuration"
                log_info "Try running: sudo nixos-generate-config manually"
                return 1
            fi
        fi
    elif [[ "$COPY_HARDWARE_FROM_REPO" == "true" ]]; then
        log_info "Copying hardware configuration from repository..."
        if [[ -f "hardware-configuration.nix" ]]; then
            # Check compatibility and syntax
            fix_nixos_25_compatibility "hardware-configuration.nix"
            if ! check_nix_syntax "hardware-configuration.nix" "hardware-configuration.nix"; then
                log_error "Syntax error in hardware-configuration.nix"
                return 1
            fi
            
            # Create backup and copy
            backup_file "/etc/nixos/hardware-configuration.nix"
            safe_copy "hardware-configuration.nix" "/etc/nixos/hardware-configuration.nix"
            hardware_handled=true
            log_success "Hardware configuration copied from repository"
        else
            log_error "hardware-configuration.nix not found in repository"
            return 1
        fi
    else
        # Default behavior - leave hardware configuration unchanged
        log_info "Hardware configuration left unchanged (default behavior)"
        if [[ ! -f "/etc/nixos/hardware-configuration.nix" ]]; then
            log_warning "No existing hardware-configuration.nix found"
            log_info "Consider using --auto-hardware to generate one"
            log_info "Or run 'sudo nixos-generate-config' manually"
        else
            log_info "Using existing /etc/nixos/hardware-configuration.nix"
        fi
        hardware_handled=true
    fi
    
    # Check file syntax before installation
    if ! check_nix_syntax "configuration.nix" "configuration.nix"; then
        log_error "Syntax error in configuration.nix"
        return 1
    fi
    
    # Verify that we have a hardware configuration
    if [[ ! -f "/etc/nixos/hardware-configuration.nix" ]]; then
        log_error "No hardware-configuration.nix found and none was created"
        log_info "Use --auto-hardware to generate one automatically"
        return 1
    fi
    
    # Create backup of existing configuration
    backup_file "/etc/nixos/configuration.nix"
    
    # Copy new main configuration
    safe_copy "configuration.nix" "/etc/nixos/configuration.nix"
    
    if [[ "$hardware_handled" == "true" ]]; then
        log_success "System configurations installed successfully"
    else
        log_warning "hardware-configuration.nix not found in repository, using existing one"
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
    
    # Hardware configuration with status
    if [[ -f "/etc/nixos/hardware-configuration.nix" ]]; then
        if [[ "$AUTO_GENERATE_HARDWARE" == "true" ]]; then
            # Check if it contains fallback indicator
            if grep -q "auto-generated fallback" "/etc/nixos/hardware-configuration.nix"; then
                echo "  ⚠ /etc/nixos/hardware-configuration.nix (fallback config - review required)"
            else
                echo "  ✓ /etc/nixos/hardware-configuration.nix (auto-generated)"
            fi
        elif [[ "$COPY_HARDWARE_FROM_REPO" == "true" ]]; then
            echo "  ✓ /etc/nixos/hardware-configuration.nix (copied from repository)"
        else
            echo "  ✓ /etc/nixos/hardware-configuration.nix (existing, unchanged)"
        fi
    else
        echo "  ⚠ /etc/nixos/hardware-configuration.nix (missing)"
        echo "    Run: sudo nixos-generate-config or use --auto-hardware option"
    fi
    
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
    
    # Check if fallback hardware config was used
    if [[ -f "/etc/nixos/hardware-configuration.nix" ]] && grep -q "auto-generated fallback" "/etc/nixos/hardware-configuration.nix"; then
        echo
        echo -e "${YELLOW}⚠️  Hardware Configuration Notice:${NC}"
        echo "A fallback hardware configuration was created because auto-detection failed."
        echo "Please review and adjust the following in /etc/nixos/hardware-configuration.nix:"
        echo "- File system device paths (check with 'lsblk' or 'fdisk -l')"
        echo "- Boot partition settings"
        echo "- Swap configuration if needed"
        echo "- Run 'sudo nixos-generate-config' manually if issues persist"
    fi
    
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
