# Absolutely minimal NixOS configuration for emergency recovery
{ config, pkgs, ... }:

{
  # Use automatic hardware detection
  imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];

  # Bootloader - minimal configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Auto-detect file systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # No swap for simplicity
  swapDevices = [ ];

  # Network
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Basic locale
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  # Minimal user
  users.users.lav = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    password = "lav";
  };

  # Absolutely minimal packages
  environment.systemPackages = with pkgs; [
    vim
    nano
    firefox
  ];

  # Allow unfree
  nixpkgs.config.allowUnfree = true;

  # System version
  system.stateVersion = "24.05";
}
