# Минимальная конфигурация NixOS + Hyprland для стабильной работы
# После успешной установки можно постепенно добавлять компоненты

{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "Europe/Moscow";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Keyboard
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle";
    };
  };
  console.keyMap = "us";

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User
  users.users.lav = {
    isNormalUser = true;
    description = "Lav";
    extraGroups = [ "networkmanager" "wheel" ];
    password = "lav";
  };

  # Basic packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    wget
    curl
    git
    firefox
    
    # Wayland essentials
    waybar
    kitty
    foot  # Alternative terminal
    rofi-wayland
    mako
    grim
    slurp
    wl-clipboard
    xfce.thunar
    
    # Basic utilities
    brightnessctl
    pavucontrol
    networkmanagerapplet
  ];

  # Fonts configuration
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    dejavu_fonts
    liberation_ttf
  ];

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  # Graphics
  hardware.graphics.enable = true;

  # Basic services
  services.dbus.enable = true;
  security.polkit.enable = true;

  system.stateVersion = "24.05";
}