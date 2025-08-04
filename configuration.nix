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
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
    # Поддержка дополнительных локалей
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ];
  };

  # Переменные окружения для правильной работы с UTF-8
  environment.variables = {
    # Принудительное включение UTF-8
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    # Для терминалов
    TERM = "xterm-256color";
    # Для правильного отображения русских символов в Hyprland
    XKB_DEFAULT_LAYOUT = "us,ru";
    XKB_DEFAULT_OPTIONS = "grp:alt_shift_toggle";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable Wayland
  security.polkit.enable = true;
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

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
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Environment variables for Hyprland (VirtualBox optimized)
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    # VirtualBox specific optimizations
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    MESA_D3D12_DEFAULT_ADAPTER_NAME = "NONE";
  };

  # Enable hardware acceleration (VirtualBox compatible)
  # Updated for NixOS 24.05+ (hardware.opengl -> hardware.graphics)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # VirtualBox doesn't support many modern graphics features
    extraPackages = with pkgs; [
      mesa.drivers
    ];
  };

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Text editors
    vim
    nano
    
    # Terminal emulator
    kitty
    
    # Wayland utilities
    waybar
    rofi-wayland
    swayidle
    swaylock
    mako
    wl-clipboard
    grim
    slurp
    
    # File manager
    xfce.thunar
    
    # System utilities
    htop
    git
    wget
    curl
    neofetch
    # Утилиты для работы с кодировками и локалями
    glibc
    locale
    
    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    
    # Network tools
    networkmanagerapplet
    
    # Audio/Video
    pavucontrol
    vlc
    
    # Development tools (optional)
    vscode
    
    # VirtualBox specific tools
    virtualbox-guest-additions-iso
  ];

  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      # Дополнительные шрифты для лучшей поддержки Unicode
      dejavu_fonts
      font-awesome
      source-code-pro
      # Монопространственные шрифты для терминала
      jetbrains-mono
      cascadia-code
    ];
    
    # Настройки fontconfig для правильного отображения
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "DejaVu Serif" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        monospace = [ "JetBrains Mono" "Fira Code" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "lav";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you know that comments are allowed here too?
}
