# Полная конфигурация NixOS + Hyprland со всеми возможностями
# Используйте после успешной установки минимальной версии

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
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support
  services.xserver.libinput.enable = true;

  # User
  users.users.lav = {
    isNormalUser = true;
    description = "Lav";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "docker" ];
    password = "lav";
  };

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # System tools
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    zip
    neofetch
    ripgrep
    fd
    bat
    exa
    vifm
    
    # Development tools
    docker
    nodejs
    
    # User applications
    firefox
    thunderbird
    telegram-desktop
    discord
    vscode
    gimp
    libreoffice
    vlc
    obs-studio
    qbittorrent
    chromium
    
    # Hyprland and Wayland
    hyprland
    xdg-desktop-portal-hyprland
    waybar
    rofi-wayland
    mako
    swayidle
    swaylock-effects
    
    # Terminal and shell
    kitty
    fish
    starship
    
    # File manager
    xfce.thunar
    
    # Screenshots
    grim
    slurp
    wl-clipboard
    cliphist
    
    # Audio and network
    pavucontrol
    networkmanagerapplet
    blueman
    
    # Brightness control
    brightnessctl
    
    # Additional utilities
    xfce.thunar-archive-plugin
    file-roller
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerdfonts
    jetbrains-mono
    fira-code
    font-awesome
    liberation_ttf
    dejavu_fonts
  ];

  # Programs
  programs.firefox.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # Security
  security.polkit.enable = true;

  # Virtualization
  virtualisation.docker.enable = true;

  # Services
  services.dbus.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  system.stateVersion = "24.05";
}
