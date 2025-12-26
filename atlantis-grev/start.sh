#!/bin/bash

echo "============================================"
echo "  🚀 ATLANTIS GREV - АВТОЗАПУСК"
echo "============================================"
echo ""

# Загрузка конфигурации
echo "[1/4] Загрузка конфигурации..."
if [ ! -f "config.txt" ]; then
    echo "❌ Файл config.txt не найден!"
    echo "Создай его или переименуй config.example.txt в config.txt"
    exit 1
fi

# Парсинг config.txt
while IFS='=' read -r key value; do
    # Пропуск комментариев и пустых строк
    if [[ ! $key =~ ^# ]] && [[ -n $key ]]; then
        # Удаление пробелов
        key=$(echo "$key" | tr -d ' ')
        value=$(echo "$value" | tr -d ' ')
        export "$key=$value"
    fi
done < config.txt

echo "✅ Конфигурация загружена"

# Проверка обязательных параметров
if [ "$SUPABASE_URL" = "https://your-project.supabase.co" ]; then
    echo ""
    echo "❌ SUPABASE_URL не настроен!"
    echo "Открой config.txt и заполни SUPABASE_URL"
    exit 1
fi

if [ "$SUPABASE_KEY" = "your-supabase-anon-key-here" ]; then
    echo ""
    echo "❌ SUPABASE_KEY не настроен!"
    echo "Открой config.txt и заполни SUPABASE_KEY"
    exit 1
fi

if [ "$CRYPTOPAY_TOKEN" = "your-cryptopay-token-here" ]; then
    echo ""
    echo "❌ CRYPTOPAY_TOKEN не настроен!"
    echo "Открой config.txt и заполни CRYPTOPAY_TOKEN"
    exit 1
fi

# Создание appsettings.json для Backend
echo ""
echo "[2/4] Настройка Backend API..."
cat > backend/AtlantisGrev.API/appsettings.json << EOF
{
  "Supabase": {
    "Url": "$SUPABASE_URL",
    "AnonKey": "$SUPABASE_KEY"
  },
  "CryptoPay": {
    "Token": "$CRYPTOPAY_TOKEN"
  },
  "Jwt": {
    "Secret": "$JWT_SECRET",
    "Issuer": "$JWT_ISSUER",
    "ExpirationDays": "$JWT_EXPIRATION_DAYS"
  },
  "WarmingService": {
    "Url": "http://localhost:$WARMING_SERVICE_PORT"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
EOF

echo "✅ Backend настроен"

# Функция для запуска в фоне
run_in_background() {
    local name=$1
    local command=$2
    local logfile="logs/$name.log"
    
    mkdir -p logs
    echo "Запуск $name..."
    nohup bash -c "$command" > "$logfile" 2>&1 &
    echo $! > "logs/$name.pid"
    echo "✅ $name запущен (PID: $(cat logs/$name.pid))"
}

# Запуск Backend API
echo ""
echo "[3/4] Запуск Backend API..."
cd backend/AtlantisGrev.API
run_in_background "backend" "dotnet run --urls=http://localhost:$BACKEND_PORT"
cd ../..
sleep 3
echo "✅ Backend запущен на http://localhost:$BACKEND_PORT"

# Запуск Warming Service
echo ""
echo "[4/4] Запуск Warming Service..."
cd warming-service/AtlantisGrev.WarmingService
export BACKEND_API_URL="http://localhost:$BACKEND_PORT"
export MAX_CONCURRENT_JOBS="$MAX_CONCURRENT_JOBS"
run_in_background "warming-service" "dotnet run"
cd ../..
sleep 3
echo "✅ Warming Service запущен на http://localhost:$WARMING_SERVICE_PORT"

echo ""
echo "============================================"
echo "  ✅ ВСЁ ЗАПУЩЕНО!"
echo "============================================"
echo ""
echo "🌐 Backend API: http://localhost:$BACKEND_PORT"
echo "📚 Swagger API: http://localhost:$BACKEND_PORT/swagger"
echo "🔄 Warming Service: http://localhost:$WARMING_SERVICE_PORT"
echo ""
echo "📱 Теперь можешь запустить мобильное приложение!"
echo ""
echo "📋 Логи находятся в папке logs/"
echo "💡 Чтобы остановить: ./stop.sh"
echo ""

