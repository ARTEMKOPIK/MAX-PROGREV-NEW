#!/bin/bash

echo "============================================"
echo "  🚀 ATLANTIS GREV - АВТОУСТАНОВКА"
echo "============================================"
echo ""

# Проверка .NET
echo "[1/5] Проверка .NET 8.0..."
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET 8.0 не найден!"
    echo ""
    echo "📥 Скачай и установи .NET 8.0:"
    echo "https://dotnet.microsoft.com/download/dotnet/8.0"
    echo ""
    echo "После установки запусти этот скрипт снова."
    exit 1
fi
echo "✅ .NET 8.0 найден"

# Проверка Flutter
echo ""
echo "[2/5] Проверка Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "⚠️ Flutter не найден!"
    echo ""
    echo "Flutter нужен только для сборки мобильного приложения."
    echo "Если хочешь только запустить Backend - можешь пропустить."
    echo ""
    echo "📥 Скачать Flutter: https://docs.flutter.dev/get-started/install"
    echo ""
    read -p "Пропустить проверку Flutter? (y/n): " skip
    if [[ ! "$skip" =~ ^[Yy]$ ]]; then
        exit 1
    fi
    echo "⚠️ Flutter пропущен"
else
    echo "✅ Flutter найден"
fi

# Проверка Chrome
echo ""
echo "[3/5] Проверка Google Chrome..."
if command -v google-chrome &> /dev/null || command -v google-chrome-stable &> /dev/null || [[ -d "/Applications/Google Chrome.app" ]]; then
    echo "✅ Chrome найден"
else
    echo "⚠️ Chrome не найден"
    echo "Chrome нужен для автоматизации WhatsApp"
    echo "📥 Скачать: https://www.google.com/chrome/"
    echo ""
    read -p "Пропустить? (y/n): " skip
    if [[ ! "$skip" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Установка зависимостей Backend
echo ""
echo "[4/5] Установка зависимостей Backend..."
cd backend/AtlantisGrev.API
dotnet restore
if [ $? -ne 0 ]; then
    echo "❌ Ошибка установки Backend"
    exit 1
fi
cd ../..
echo "✅ Backend готов"

# Установка зависимостей Warming Service
echo ""
echo "[5/5] Установка зависимостей Warming Service..."
cd warming-service/AtlantisGrev.WarmingService
dotnet restore
if [ $? -ne 0 ]; then
    echo "❌ Ошибка установки Warming Service"
    exit 1
fi
cd ../..
echo "✅ Warming Service готов"

# Установка зависимостей Mobile (если Flutter доступен)
if command -v flutter &> /dev/null; then
    echo ""
    echo "[БОНУС] Установка зависимостей Mobile..."
    cd mobile/atlantis_grev_mobile
    flutter pub get
    cd ../..
    echo "✅ Mobile готов"
fi

echo ""
echo "============================================"
echo "  ✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo "============================================"
echo ""
echo "📝 ЧТО ДАЛЬШЕ:"
echo ""
echo "1. Открой файл config.txt"
echo "2. Заполни SUPABASE_URL, SUPABASE_KEY, CRYPTOPAY_TOKEN"
echo "3. Запусти ./start.sh"
echo ""
echo "🎉 Готово!"
echo ""

