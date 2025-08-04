#!/usr/bin/env bash
# Скрипт для установки правильных прав доступа к файлам

echo "🔧 Установка правильных прав доступа..."

# Скрипты должны быть исполняемыми
chmod +x install-configs.sh
chmod +x diagnose-config.sh  
chmod +x fix-config.sh
chmod +x fix-encoding.sh
chmod +x test-encoding.sh

# Конфигурационные файлы должны быть читаемыми
chmod 644 *.nix
chmod 644 *.conf
chmod 644 *.json
chmod 644 *.css

# Документация должна быть читаемой
chmod 644 *.md

echo "✅ Права доступа установлены"
echo "📋 Исполняемые файлы:"
ls -la *.sh

echo "📋 Конфигурационные файлы:"
ls -la *.nix *.conf *.json *.css
