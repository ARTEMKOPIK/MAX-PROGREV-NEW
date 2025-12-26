@echo off
chcp 65001 >nul
echo ============================================
echo   🚀 ATLANTIS GREV - АВТОЗАПУСК
echo ============================================
echo.

REM Загрузка конфигурации
echo [1/4] Загрузка конфигурации...
if not exist "config.txt" (
    echo ❌ Файл config.txt не найден!
    echo Создай его или переименуй config.example.txt в config.txt
    pause
    exit /b 1
)

REM Парсинг config.txt
for /f "tokens=1,2 delims==" %%a in ('type config.txt ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set %%a=%%b
)

echo ✅ Конфигурация загружена

REM Проверка обязательных параметров
if "%SUPABASE_URL%"=="https://your-project.supabase.co" (
    echo.
    echo ❌ SUPABASE_URL не настроен!
    echo Открой config.txt и заполни SUPABASE_URL
    pause
    exit /b 1
)

if "%SUPABASE_KEY%"=="your-supabase-anon-key-here" (
    echo.
    echo ❌ SUPABASE_KEY не настроен!
    echo Открой config.txt и заполни SUPABASE_KEY
    pause
    exit /b 1
)

if "%CRYPTOPAY_TOKEN%"=="your-cryptopay-token-here" (
    echo.
    echo ❌ CRYPTOPAY_TOKEN не настроен!
    echo Открой config.txt и заполни CRYPTOPAY_TOKEN
    pause
    exit /b 1
)

REM Создание appsettings.json для Backend
echo.
echo [2/4] Настройка Backend API...
(
echo {
echo   "Supabase": {
echo     "Url": "%SUPABASE_URL%",
echo     "AnonKey": "%SUPABASE_KEY%"
echo   },
echo   "CryptoPay": {
echo     "Token": "%CRYPTOPAY_TOKEN%"
echo   },
echo   "Jwt": {
echo     "Secret": "%JWT_SECRET%",
echo     "Issuer": "%JWT_ISSUER%",
echo     "ExpirationDays": "%JWT_EXPIRATION_DAYS%"
echo   },
echo   "WarmingService": {
echo     "Url": "http://localhost:%WARMING_SERVICE_PORT%"
echo   },
echo   "Logging": {
echo     "LogLevel": {
echo       "Default": "Information"
echo     }
echo   },
echo   "AllowedHosts": "*"
echo }
) > backend\AtlantisGrev.API\appsettings.json

echo ✅ Backend настроен

REM Запуск Backend API
echo.
echo [3/4] Запуск Backend API...
cd backend\AtlantisGrev.API
start "Atlantis Grev - Backend API" cmd /k "dotnet run --urls=http://localhost:%BACKEND_PORT%"
cd ..\..
timeout /t 3 /nobreak >nul
echo ✅ Backend запущен на http://localhost:%BACKEND_PORT%

REM Запуск Warming Service
echo.
echo [4/4] Запуск Warming Service...
cd warming-service\AtlantisGrev.WarmingService
set BACKEND_API_URL=http://localhost:%BACKEND_PORT%
set MAX_CONCURRENT_JOBS=%MAX_CONCURRENT_JOBS%
start "Atlantis Grev - Warming Service" cmd /k "dotnet run"
cd ..\..
timeout /t 3 /nobreak >nul
echo ✅ Warming Service запущен на http://localhost:%WARMING_SERVICE_PORT%

echo.
echo ============================================
echo   ✅ ВСЁ ЗАПУЩЕНО!
echo ============================================
echo.
echo 🌐 Backend API: http://localhost:%BACKEND_PORT%
echo 📚 Swagger API: http://localhost:%BACKEND_PORT%/swagger
echo 🔄 Warming Service: http://localhost:%WARMING_SERVICE_PORT%
echo.
echo 📱 Теперь можешь запустить мобильное приложение!
echo.
echo 💡 Чтобы остановить - закрой все окна терминала
echo.
pause

