# Исправление ошибок конфигурации NixOS

## Проблема
Ошибки при выполнении `sudo nixos-rebuild switch`:
- `sound.enable` больше не имеет эффекта
- `hardware.opengl.driSupport` больше не имеет эффекта

## Быстрое решение

### Вариант 1: Автоматическое исправление
```bash
# Сделать скрипты исполняемыми
chmod +x diagnose-config.sh fix-config.sh

# Диагностика проблем
./diagnose-config.sh

# Автоматическое исправление (требует sudo)
sudo ./fix-config.sh
```

### Вариант 2: Использование чистой конфигурации
```bash
# Создать резервную копию
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup

# Заменить на исправленную версию
sudo cp configuration-clean.nix /etc/nixos/configuration.nix

# Проверить сборку
sudo nixos-rebuild dry-build

# Применить изменения
sudo nixos-rebuild switch
```

### Вариант 3: Ручное исправление

Отредактируйте `/etc/nixos/configuration.nix`:

1. **Удалите строку:**
   ```nix
   sound.enable = true;
   ```

2. **Замените блок:**
   ```nix
   # Было:
   hardware.opengl = {
     enable = true;
     driSupport = true;
     driSupport32Bit = true;
   };
   
   # Стало:
   hardware.graphics = {
     enable = true;
     enable32Bit = true;
   };
   ```

## Проверка версии NixOS
```bash
nixos-version
```

Если у вас версия младше 24.05, используйте старые опции из файла `VERSION-COMPATIBILITY.md`.

## В случае проблем

### Откат к предыдущей конфигурации:
```bash
sudo nixos-rebuild switch --rollback
```

### Восстановление из резервной копии:
```bash
sudo cp /etc/nixos/configuration.nix.backup /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

### Показать подробную трассировку ошибок:
```bash
sudo nixos-rebuild switch --show-trace
```

## Полезные команды для диагностики

```bash
# Проверка синтаксиса конфигурации
nix-instantiate --parse /etc/nixos/configuration.nix

# Проверка конфигурации без применения
sudo nixos-rebuild dry-build

# Показать различия между текущей и новой конфигурацией
sudo nixos-rebuild build
nix store diff-closures /run/current-system ./result

# Проверка доступных поколений
sudo nixos-rebuild list-generations
```
