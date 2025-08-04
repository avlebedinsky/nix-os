# 🔧 Исправление синтаксической ошибки

## Проблема
```
error: syntax error, unexpected end of file, expecting INHERIT
at /etc/nixos/hardware-configuration.nix:48:1:
```

## Решение

### Быстрое исправление:
```bash
# Автоматическое исправление
./fix-syntax.sh
```

### Ручное исправление:
1. Откройте файл `hardware-configuration.nix`
2. Убедитесь, что файл заканчивается закрывающей скобкой `}`
3. Проверьте, что все открывающие скобки `{` имеют соответствующие закрывающие `}`

### Пример корректного окончания файла:
```nix
  # CPU settings for VirtualBox
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  
  # No specific CPU microcode updates needed in VM
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}  # ← Эта скобка обязательна!
```

## Проверка исправления:
```bash
# Проверка синтаксиса без применения
sudo nixos-rebuild dry-build

# Если всё ОК - применение
sudo nixos-rebuild switch
```

## Профилактика:
- Используйте `./install-configs.sh` - он автоматически проверяет синтаксис
- Регулярно запускайте `./diagnose-config.sh` для проверки системы
