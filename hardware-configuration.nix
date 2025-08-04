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

  # File systems configuration 
  # IMPORTANT: These need to be updated with actual UUIDs from your system
  # Run: sudo blkid to get the correct UUIDs
  fileSystems."/" =
    { device = "/dev/sda1";  # Using device path instead of UUID temporarily
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/sda2";  # Using device path instead of UUID temporarily
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
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
