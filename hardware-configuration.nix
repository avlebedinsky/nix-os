# Hardware configuration for NixOS in VirtualBox
# This file is optimized for VirtualBox virtual machines

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Boot configuration for VirtualBox
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems configuration with fallback options
  # Try multiple device detection methods
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "defaults" ];
  };

  # Swap configuration - comment out if no swap
  # swapDevices = [ { device = "/dev/sda3"; } ];
  swapDevices = [ ];

  # VirtualBox specific optimizations
  # Enable VirtualBox Guest Additions
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;

  # Networking for VirtualBox
  networking.useDHCP = lib.mkDefault true;

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # CPU settings for VirtualBox (usually no frequency scaling needed)
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  
  # No specific CPU microcode updates needed in VM
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
