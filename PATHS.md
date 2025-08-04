# Структура конфигураций для NixOS + Hyprland

## Системные конфигурации (требуют root)

```
/etc/nixos/
├── configuration.nix           # Основная конфигурация NixOS
├── hardware-configuration.nix  # Конфигурация оборудования
├── flake.nix                   # Flake конфигурация (опционально)
└── flake.lock                  # Блокировка версий (опционально)
```

## Пользовательские конфигурации

```
~/.config/
├── hypr/
│   ├── hyprland.conf          # Основная конфигурация Hyprland
│   ├── hyprpaper.conf         # Обои (если используете hyprpaper)
│   └── hypridle.conf          # Настройки idle (новая версия)
│
├── waybar/
│   ├── config                 # Конфигурация панели
│   └── style.css             # Стили панели
│
├── kitty/
│   └── kitty.conf            # Терминал
│
├── rofi/
│   ├── config.rasi           # Лаунчер приложений
│   └── themes/               # Темы для rofi
│
├── mako/
│   └── config                # Уведомления
│
├── swayidle/
│   └── config                # Настройки простоя (deprecated, используйте hypridle)
│
├── thunar/
│   └── uca.xml               # Пользовательские действия файлового менеджера
│
├── gtk-3.0/
│   └── settings.ini          # Настройки GTK тем
│
└── fontconfig/
    └── fonts.conf            # Настройки шрифтов
```

## Home Manager конфигурации (если используется)

```
~/.config/nixpkgs/
├── home.nix                  # Основная конфигурация Home Manager
├── programs/                 # Конфигурации программ
│   ├── hyprland.nix
│   ├── waybar.nix
│   ├── kitty.nix
│   └── rofi.nix
└── services/                 # Сервисы пользователя
    ├── mako.nix
    └── hypridle.nix
```

## Дополнительные важные пути

```
# Wallpapers (обои)
~/Pictures/Wallpapers/

# Scripts (скрипты)
~/.local/bin/
~/Scripts/

# Темы
~/.themes/                    # GTK темы
~/.icons/                     # Иконки

# Кэш и временные файлы
~/.cache/hyprland/
~/.cache/waybar/

# Логи
~/.local/share/hyprland/      # Логи Hyprland
```

## Системные пути

```
# Темы и иконки (системные)
/usr/share/themes/
/usr/share/icons/
/run/current-system/sw/share/themes/
/run/current-system/sw/share/icons/

# Шрифты
/run/current-system/sw/share/fonts/
~/.local/share/fonts/

# Desktop файлы приложений
/run/current-system/sw/share/applications/
~/.local/share/applications/
```

## Переменные окружения для путей

В Hyprland можно использовать переменные:
- `$HOME` - домашняя директория
- `$XDG_CONFIG_HOME` - обычно ~/.config
- `$XDG_DATA_HOME` - обычно ~/.local/share
- `$XDG_CACHE_HOME` - обычно ~/.cache

## Полезные команды для работы с конфигурациями

```bash
# Найти все конфигурационные файлы
find ~/.config -name "*.conf" -o -name "*.json" -o -name "*.rasi"

# Создать символические ссылки на конфигурации
ln -sf /path/to/your/configs/hyprland.conf ~/.config/hypr/hyprland.conf

# Проверить синтаксис конфигурации Hyprland
hyprland --check

# Перезагрузить конфигурацию Hyprland без перезапуска
hyprctl reload
```
