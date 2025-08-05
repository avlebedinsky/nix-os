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
├── mako-config.conf       # Система уведомлений
├── swaylock-config.conf   # Экран блокировки
├── swayidle-config.sh     # Автоблокировка экрана
├── install.sh             # Скрипт установки
├── ADDITIONAL-CONFIGS.md  # Документация новых возможностей
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
- 📁 **Файловый менеджер** - Thunar с поддержкой архивов
- 🔊 **Звук через PipeWire** - современный аудио стек
- 📷 **Скриншоты** - Grim + Slurp + буфер обмена
- 🔔 **Уведомления** - стильные уведомления Mako
- 🔒 **Блокировка экрана** - красивый Swaylock с автоблокировкой
- 🔵 **Bluetooth и сеть** - готовые менеджеры
- 💾 **Автомонтирование USB** - plug & play
- 🔐 **Безопасность** - keyring и polkit
- 🎯 **Все настроено** - просто используйте!

Полнофункциональная рабочая станция с пользователем `lav` (пароль: `lav`).
