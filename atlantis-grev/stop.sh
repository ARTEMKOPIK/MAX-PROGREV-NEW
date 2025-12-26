#!/bin/bash

echo "============================================"
echo "  🛑 ATLANTIS GREV - ОСТАНОВКА"
echo "============================================"
echo ""

# Остановка процессов
if [ -f "logs/backend.pid" ]; then
    echo "Остановка Backend API..."
    kill $(cat logs/backend.pid) 2>/dev/null
    rm logs/backend.pid
    echo "✅ Backend остановлен"
fi

if [ -f "logs/warming-service.pid" ]; then
    echo "Остановка Warming Service..."
    kill $(cat logs/warming-service.pid) 2>/dev/null
    rm logs/warming-service.pid
    echo "✅ Warming Service остановлен"
fi

echo ""
echo "✅ Все сервисы остановлены!"
echo ""

