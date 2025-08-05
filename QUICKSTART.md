# NixOS + Hyprland - Готовая конфигурация

## 📂 Структура проекта

```
nix-os/
├── configuration.nix       # Минимальная стабильная конфигурация
├── configuration-full.nix  # Полная конфигурация (для опытных)
├── hyprland.conf          # Конфигурация Hyprland WM (упрощена)
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

### 🚀 Обновление до полной версии:
После успешной установки минимальной версии:
```bash
cp configuration-full.nix configuration.nix
sudo nixos-rebuild switch
```

## ✨ Что включено (минимальная версия)

- 🎨 **Красивый интерфейс** - Hyprland с базовыми анимациями
- 🇷🇺 **Русская локализация** - переключение Alt+Shift  
- ⌨️ **Основные hotkeys** - Super+T (терминал), Super+R (launcher)
-  **Файловый менеджер** - Thunar
- 🔊 **Звук через PipeWire** - современный аудио стек
- 📷 **Скриншоты** - Grim + Slurp
- 🔔 **Уведомления** - Mako
- 🎯 **Стабильная работа** - минимум компонентов, максимум надежности

**Стабильная рабочая станция** с пользователем `lav` (пароль: `lav`).

💡 **Подсказка:** После установки используйте `configuration-full.nix` для получения всех возможностей!
