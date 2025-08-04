# README - NixOS с Hyprland

Этот репозиторий содержит базовую конфигурацию для NixOS с оконным менеджером Hyprland.

## Файлы конфигурации

### `configuration.nix`
Основной файл конфигурации NixOS, который включает:
- Базовые настройки системы
- Поддержку Hyprland и Wayland
- Необходимые пакеты для работы с Hyprland
- Настройки звука через PipeWire
- Базовые приложения и утилиты

### `hyprland.conf`
Конфигурация Hyprland с:
- Базовыми привязками клавиш (Super как основная клавиша-модификатор)
- Настройками анимации и декораций
- Автозапуском необходимых сервисов
- Правилами для окон

### `hardware-configuration.nix`
Шаблон конфигурации оборудования (требует адаптации под ваше железо)

### `waybar-config.json` и `waybar-style.css`
Конфигурация и стили для панели Waybar

## Установка

**⚠️ ВАЖНО: Проверьте совместимость версий!**
Эта конфигурация предназначена для NixOS 24.05+. Для более старых версий см. `VERSION-COMPATIBILITY.md`.

Проверить версию: `nixos-version`

1. **Создайте hardware-configuration.nix для вашей системы:**
   ```bash
   sudo nixos-generate-config --root /mnt
   ```
   Скопируйте содержимое сгенерированного `hardware-configuration.nix`

2. **Скопируйте конфигурацию:**
   ```bash
   sudo cp configuration.nix /etc/nixos/
   sudo cp hardware-configuration.nix /etc/nixos/
   ```

3. **Создайте пользователя и установите пароль:**
   Измените имя пользователя в `configuration.nix` и выполните:
   ```bash
   sudo nixos-rebuild switch
   sudo passwd ваше_имя_пользователя
   ```

4. **Скопируйте конфигурацию Hyprland:**
   ```bash
   mkdir -p ~/.config/hypr
   cp hyprland.conf ~/.config/hypr/
   ```

5. **Настройте Waybar:**
   ```bash
   mkdir -p ~/.config/waybar
   cp waybar-config.json ~/.config/waybar/config
   cp waybar-style.css ~/.config/waybar/style.css
   ```

## Основные горячие клавиши

- `Super + T` - Открыть терминал (Kitty)
- `Super + R` - Запустить приложение (Rofi)
- `Super + Q` - Закрыть окно
- `Super + M` - Выйти из Hyprland
- `Super + F` - Полноэкранный режим
- `Super + V` - Переключить плавающий режим
- `Super + E` - Файловый менеджер (Thunar)
- `Super + 1-9` - Переключиться на рабочий стол
- `Super + Shift + 1-9` - Переместить окно на рабочий стол
- `Print` - Скриншот области
- `Super + Print` - Скриншот всего экрана

## Дополнительные настройки

### Обои
```bash
# Установите feh или swww для обоев
nix-shell -p feh
feh --bg-scale /path/to/wallpaper.jpg
```

### Автоматический вход
По умолчанию включен автоматический вход для пользователя. Отключите в `configuration.nix` если не нужно:
```nix
# Закомментируйте эту строку:
# services.getty.autologinUser = "user";
```

### Дополнительные пакеты
Добавьте нужные пакеты в список `environment.systemPackages` в `configuration.nix`.

## Обновление системы

```bash
sudo nixos-rebuild switch
```

## Полезные команды

- `nixos-option` - Просмотр опций конфигурации
- `nix search` - Поиск пакетов
- `nix-collect-garbage` - Очистка старых поколений
- `nixos-rebuild switch --rollback` - Откат к предыдущей конфигурации

## Troubleshooting

1. **Проблемы с графикой:** Проверьте настройки `hardware.opengl` в конфигурации
2. **Не работает звук:** Убедитесь, что PipeWire запущен: `systemctl --user status pipewire`
3. **Проблемы с клавиатурой:** Проверьте настройки раскладки в Hyprland и X11

Для получения дополнительной помощи обратитесь к документации NixOS и Hyprland.
