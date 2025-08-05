# NixOS + Hyprland - Готовая конфигурация

## 📂 Структура проекта

```
nix-os/
├── configuration.nix       # Главная конфигурация NixOS
├── hyprland.conf          # Конфигурация Hyprland WM
├── waybar-config.json     # Панель Waybar
├── waybar-style.css       # Стили для Waybar  
├── kitty.conf             # Терминал Kitty
├── fish-config.fish       # Shell Fish с алиасами
├── gitconfig              # Глобальные настройки Git
├── install.sh             # Скрипт установки
├── additional-packages.md # Дополнительные пакеты
└── README.md              # Документация
```

## 🚀 Быстрый старт

1. **Клонируйте или скачайте файлы**
2. **Запустите установку:**
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```
3. **Пересоберите систему:**
   ```bash
   sudo nixos-rebuild switch
   ```
4. **Перезагрузитесь и выберите Hyprland**

## ✨ Что включено

- 🎨 **Красивый интерфейс** - Hyprland с анимациями
- 🇷🇺 **Русская локализация** - переключение Alt+Shift  
- ⌨️ **Удобные hotkeys** - Super+T (терминал), Super+R (launcher)
- 🔧 **Готовые алиасы** - `rebuild`, `nix-clean` в Fish shell
- 📁 **Файловый менеджер** - Thunar
- 🔊 **Звук через PipeWire** - современный аудио стек
- 📷 **Скриншоты** - Grim + Slurp
- 🎯 **Все настроено** - просто используйте!

Минималистичная, но полнофункциональная конфигурация для продуктивной работы.
