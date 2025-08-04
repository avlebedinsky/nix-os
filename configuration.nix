# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable Wayland
  security.polkit.enable = true;
  
  # Configure keymap in X11
  services.xserver.xkb.layout = "us";

  # Configure console keymap
  console.keyMap = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable is deprecated in NixOS 24.05+
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable Hyprland
  programs.hyprland.enable = true;

  # Enable hardware acceleration
  hardware.graphics.enable = true;

  # VirtualBox specific services
  services.spice-vdagentd.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.lav = {
    isNormalUser = true;
    description = "Lav";
    extraGroups = [ "networkmanager" "wheel" ];
    password = "lav";
    packages = with pkgs; [
      firefox
      tree
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    # Text editors
    vim
    nano
    
    # Terminal emulator
    kitty
    
    # Wayland utilities
    waybar
    rofi-wayland
    mako
    wl-clipboard
    
    # File manager
    xfce.thunar
    
    # System utilities
    htop
    git
    wget
    firefox
  ];

  # Basic fonts configuration
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System version
  system.stateVersion = "24.05";
}
