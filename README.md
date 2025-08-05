# NixOS + Hyprland Configuration

Полная конфигурация NixOS с оконным менеджером Hyprland, включая настройки для Waybar, Kitty терминала и другие компоненты.

## Файлы конфигурации

### Основные файлы
- `configuration.nix` - минимальная стабильная конфигурация NixOS
- `configuration-full.nix` - полная конфигурация со всеми возможностями
- `hyprland.conf` - конфигурация оконного менеджера Hyprland
- `waybar-config.json` - конфигурация панели Waybar
- `waybar-style.css` - стили для Waybar
- `kitty.conf` - конфигурация терминала Kitty
- `fish-config.fish` - конфигурация Fish shell с алиасами
- `gitconfig` - глобальная конфигурация Git

### Дополнительные конфигурации
- `mako-config.conf` - конфигурация системы уведомлений
- `swaylock-config.conf` - конфигурация экрана блокировки
- `swayidle-config.sh` - скрипт автоматической блокировки

### Служебные файлы
- `install.sh` - скрипт автоматической установки
- `ADDITIONAL-CONFIGS.md` - документация по дополнительным конфигурациям
- `QUICKSTART.md` - краткое руководство по установке

## Особенности конфигурации

### NixOS (configuration.nix)
- Поддержка русского и английского языков
- Настройка клавиатуры (переключение Alt+Shift)
- PipeWire для аудио
- Hyprland как основной DE
- Полный набор необходимых пакетов
- Шрифты Nerd Fonts
- Поддержка Wayland

### Hyprland (hyprland.conf)
- Красивые анимации и эффекты
- Настроенные горячие клавиши
- Поддержка нескольких рабочих столов
- Автозапуск Waybar и других приложений
- Настройка для мультимониторных систем

### Waybar
- Информативная панель с системными метриками
- Поддержка рабочих столов Hyprland
- Красивая цветовая схема
- Иконки Font Awesome

### Kitty Terminal
- Шрифт JetBrains Mono
- Цветовая схема One Dark
- Поддержка UTF-8
- Настроенные горячие клавиши

### Fish Shell
- Удобные алиасы для NixOS (`rebuild`, `nix-clean`)
- Настроенные переменные окружения для Wayland
- Полезные функции (backup, extract, mkcd)
- Поддержка Starship prompt

### Git
- Предустановленные алиасы
- Красивая цветовая схема
- Настроенные инструменты merge/diff

## Установка

### Быстрая установка
```bash
# Клонируйте репозиторий или скопируйте файлы
# Сделайте скрипт исполняемым
chmod +x install.sh

# Запустите установку
sudo ./install.sh
```

### Ручная установка

1. **Скопируйте configuration.nix:**
```bash
sudo cp configuration.nix /etc/nixos/
```

2. **Создайте каталоги конфигурации:**
```bash
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/kitty
```

3. **Скопируйте конфигурационные файлы:**
```bash
cp hyprland.conf ~/.config/hypr/
cp waybar-config.json ~/.config/waybar/config
cp waybar-style.css ~/.config/waybar/style.css
cp kitty.conf ~/.config/kitty/
```

4. **Перестройте систему:**
```bash
sudo nixos-rebuild switch
```

5. **Перезагрузите систему:**
```bash
sudo reboot
```

## После установки

1. При входе в систему выберите **Hyprland** в качестве сессии
2. Система автоматически запустит Waybar, Mako (уведомления) и другие компоненты
3. Откройте терминал клавишей `Super + T`

## Горячие клавиши

### Основные
- `Super + T` - открыть терминал (Kitty)
- `Super + Q` - закрыть активное окно
- `Super + M` - выйти из Hyprland
- `Super + E` - открыть файловый менеджер (Thunar)
- `Super + R` - открыть launcher (Rofi)
- `Super + V` - переключить режим плавающего окна
- `Super + F` - полноэкранный режим

### Навигация
- `Super + H/J/K/L` - перемещение между окнами (Vim-style)
- `Super + 1-9` - переключение между рабочими столами
- `Super + Shift + 1-9` - перемещение окна на рабочий стол

### Скриншоты
- `Print` - скриншот области (выбрать область)
- `Super + Print` - скриншот всего экрана

### Звук и яркость
- `XF86AudioRaiseVolume/LowerVolume` - громкость
- `XF86AudioMute` - выключить звук
- `XF86MonBrightnessUp/Down` - яркость экрана

## Требования

- NixOS 24.05 или новее
- Поддержка Wayland
- Видеокарта с поддержкой OpenGL/Vulkan

## Устранение проблем

### Проблемы с видеодрайверами
Раскомментируйте соответствующие драйверы в `configuration.nix`:
```nix
# Для NVIDIA
hardware.nvidia.modesetting.enable = true;

# Для AMD
hardware.opengl.extraPackages = with pkgs; [ rocm-opencl-icd ];
```

### Проблемы с шрифтами
Убедитесь, что Nerd Fonts установлены:
```bash
fc-list | grep -i "nerd\|jetbrains"
```

### Проблемы с аудио
Проверьте статус PipeWire:
```bash
systemctl --user status pipewire
```

## Дополнительная настройка

### Добавление пользователя
Измените имя пользователя в `configuration.nix`:
```nix
users.users.ваше_имя = {
  isNormalUser = true;
  description = "Ваше имя";
  extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
  # ...
};
```

### Добавление пакетов
Добавьте нужные пакеты в `environment.systemPackages` или в `users.users.ваше_имя.packages`.

## Лицензия

Эта конфигурация предоставляется "как есть" для свободного использования и модификации.
