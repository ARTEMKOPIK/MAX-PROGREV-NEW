@echo off
chcp 65001 >nul
echo ============================================
echo   🚀 ATLANTIS GREV - АВТОУСТАНОВКА
echo ============================================
echo.

REM Проверка наличия .NET
echo [1/5] Проверка .NET 8.0...
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ .NET 8.0 не найден!
    echo.
    echo 📥 Скачай и установи .NET 8.0:
    echo https://dotnet.microsoft.com/download/dotnet/8.0
    echo.
    echo После установки запусти этот скрипт снова.
    pause
    exit /b 1
)
echo ✅ .NET 8.0 найден

REM Проверка наличия Flutter
echo.
echo [2/5] Проверка Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Flutter не найден!
    echo.
    echo Flutter нужен только для сборки мобильного приложения.
    echo Если хочешь только запустить Backend - можешь пропустить.
    echo.
    echo 📥 Скачать Flutter: https://docs.flutter.dev/get-started/install
    echo.
    set /p skip="Пропустить проверку Flutter? (y/n): "
    if /i "%skip%" neq "y" (
        pause
        exit /b 1
    )
    echo ⚠️ Flutter пропущен
) else (
    echo ✅ Flutter найден
)

REM Проверка наличия Chrome
echo.
echo [3/5] Проверка Google Chrome...
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    echo ✅ Chrome найден
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    echo ✅ Chrome найден
) else (
    echo ⚠️ Chrome не найден
    echo Chrome нужен для автоматизации WhatsApp
    echo 📥 Скачать: https://www.google.com/chrome/
    echo.
    set /p skip="Пропустить? (y/n): "
    if /i "%skip%" neq "y" (
        pause
        exit /b 1
    )
)

REM Установка зависимостей Backend
echo.
echo [4/5] Установка зависимостей Backend...
cd backend\AtlantisGrev.API
dotnet restore
if %errorlevel% neq 0 (
    echo ❌ Ошибка установки Backend
    pause
    exit /b 1
)
cd ..\..
echo ✅ Backend готов

REM Установка зависимостей Warming Service
echo.
echo [5/5] Установка зависимостей Warming Service...
cd warming-service\AtlantisGrev.WarmingService
dotnet restore
if %errorlevel% neq 0 (
    echo ❌ Ошибка установки Warming Service
    pause
    exit /b 1
)
cd ..\..
echo ✅ Warming Service готов

REM Установка зависимостей Mobile (если Flutter доступен)
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo [БОНУС] Установка зависимостей Mobile...
    cd mobile\atlantis_grev_mobile
    flutter pub get
    cd ..\..
    echo ✅ Mobile готов
)

echo.
echo ============================================
echo   ✅ УСТАНОВКА ЗАВЕРШЕНА!
echo ============================================
echo.
echo 📝 ЧТО ДАЛЬШЕ:
echo.
echo 1. Открой файл config.txt
echo 2. Заполни SUPABASE_URL, SUPABASE_KEY, CRYPTOPAY_TOKEN
echo 3. Запусти start.bat
echo.
echo 🎉 Готово!
echo.
pause

