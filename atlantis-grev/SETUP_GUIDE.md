# 🛠️ Полная Инструкция по Настройке Atlantis Grev

Пошаговая инструкция для настройки всего проекта с нуля на Windows/Linux/Mac.

---

## 📋 Содержание

1. [Установка Необходимого ПО](#1-установка-необходимого-по)
2. [Настройка Supabase (База Данных)](#2-настройка-supabase-база-данных)
3. [Получение Crypto Pay Token](#3-получение-crypto-pay-token)
4. [Настройка Backend API](#4-настройка-backend-api)
5. [Настройка Warming Service](#5-настройка-warming-service)
6. [Настройка Mobile App](#6-настройка-mobile-app)
7. [Запуск Проекта](#7-запуск-проекта)
8. [Проверка Работоспособности](#8-проверка-работоспособности)

---

## 1. Установка Необходимого ПО

### Windows

#### 1.1 .NET 8.0 SDK
```powershell
# Скачать с официального сайта:
https://dotnet.microsoft.com/download/dotnet/8.0

# Или через winget:
winget install Microsoft.DotNet.SDK.8

# Проверка установки:
dotnet --version
```

#### 1.2 Flutter SDK
```powershell
# Скачать с официального сайта:
https://docs.flutter.dev/get-started/install/windows

# Или через Chocolatey:
choco install flutter

# Проверка установки:
flutter --version
flutter doctor
```

#### 1.3 Git
```powershell
# Скачать с официального сайта:
https://git-scm.com/download/win

# Проверка:
git --version
```

#### 1.4 Chrome/Chromium
```powershell
# Скачать Chrome:
https://www.google.com/chrome/
```

### Linux (Ubuntu/Debian)

```bash
# 1. .NET 8.0 SDK
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0

# 2. Flutter
sudo snap install flutter --classic

# 3. Git (обычно уже установлен)
sudo apt-get install git

# 4. Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

# Проверка всех установок:
dotnet --version
flutter --version
git --version
google-chrome --version
```

### macOS

```bash
# 1. .NET 8.0 SDK
brew install --cask dotnet-sdk

# 2. Flutter
brew install --cask flutter

# 3. Git (обычно уже установлен)
brew install git

# 4. Chrome (обычно уже установлен)
brew install --cask google-chrome

# Проверка:
dotnet --version
flutter --version
git --version
```

---

## 2. Настройка Supabase (База Данных)

### 2.1 Создание Проекта

1. Зайдите на https://supabase.com
2. Создайте аккаунт или войдите
3. Нажмите **"New Project"**
4. Заполните форму:
   - **Name**: `atlantis-grev`
   - **Database Password**: придумайте сильный пароль
   - **Region**: выберите ближайший к вам регион
5. Нажмите **"Create new project"** (займет 1-2 минуты)

### 2.2 Получение Credentials

После создания проекта:

1. Перейдите в **Settings** → **API**
2. Скопируйте:
   - **Project URL** - это ваш `Supabase.Url`
   - **anon public** ключ - это ваш `Supabase.AnonKey`

### 2.3 Создание Таблиц

Перейдите в **SQL Editor** и выполните следующий SQL код:

```sql
-- ==========================================
-- ТАБЛИЦА 1: users (Пользователи)
-- ==========================================
CREATE TABLE public.users (
    id BIGINT PRIMARY KEY,
    telegram_id BIGINT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    paid_accounts INT DEFAULT 0,
    referrals INT DEFAULT 0,
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    referrer_id BIGINT REFERENCES public.users(id),
    affiliate_balance DECIMAL(10, 2) DEFAULT 0.00,
    total_earned DECIMAL(10, 2) DEFAULT 0.00,
    affiliate_code TEXT UNIQUE NOT NULL
);

-- Индексы для users
CREATE INDEX idx_users_telegram_id ON public.users(telegram_id);
CREATE INDEX idx_users_affiliate_code ON public.users(affiliate_code);
CREATE INDEX idx_users_referrer_id ON public.users(referrer_id);

-- ==========================================
-- ТАБЛИЦА 2: whatsapp_accounts (WhatsApp Аккаунты)
-- ==========================================
CREATE TABLE public.whatsapp_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    warming_status TEXT DEFAULT 'idle',
    session_dir TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    warming_started_at TIMESTAMP WITH TIME ZONE,
    warming_completed_at TIMESTAMP WITH TIME ZONE,
    warming_progress INT DEFAULT 0,
    is_warming BOOLEAN DEFAULT FALSE
);

-- Индексы для whatsapp_accounts
CREATE INDEX idx_accounts_user_id ON public.whatsapp_accounts(user_id);
CREATE INDEX idx_accounts_status ON public.whatsapp_accounts(status);
CREATE INDEX idx_accounts_warming_status ON public.whatsapp_accounts(warming_status);

-- ==========================================
-- ТАБЛИЦА 3: account_logs (Логи Аккаунтов)
-- ==========================================
CREATE TABLE public.account_logs (
    id BIGSERIAL PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES public.whatsapp_accounts(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    log_type TEXT DEFAULT 'info',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для account_logs
CREATE INDEX idx_logs_account_id ON public.account_logs(account_id);
CREATE INDEX idx_logs_created_at ON public.account_logs(created_at);

-- ==========================================
-- ТАБЛИЦА 4: payments (Платежи)
-- ==========================================
CREATE TABLE public.payments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    invoice_hash TEXT UNIQUE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    asset TEXT DEFAULT 'USDT',
    status TEXT DEFAULT 'pending',
    accounts_count INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Индексы для payments
CREATE INDEX idx_payments_user_id ON public.payments(user_id);
CREATE INDEX idx_payments_invoice_hash ON public.payments(invoice_hash);
CREATE INDEX idx_payments_status ON public.payments(status);

-- ==========================================
-- ТАБЛИЦА 5: withdrawals (Выводы Средств)
-- ==========================================
CREATE TABLE public.withdrawals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    wallet_address TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- Индексы для withdrawals
CREATE INDEX idx_withdrawals_user_id ON public.withdrawals(user_id);
CREATE INDEX idx_withdrawals_status ON public.withdrawals(status);

-- ==========================================
-- ФУНКЦИЯ: Генерация Affiliate Code
-- ==========================================
CREATE OR REPLACE FUNCTION generate_affiliate_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        -- Генерируем случайный 8-символьный код
        code := upper(substring(md5(random()::text) from 1 for 8));
        
        -- Проверяем уникальность
        SELECT EXISTS(SELECT 1 FROM public.users WHERE affiliate_code = code) INTO exists;
        
        EXIT WHEN NOT exists;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- ТРИГГЕР: Auto-generate affiliate code
-- ==========================================
CREATE OR REPLACE FUNCTION set_affiliate_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.affiliate_code IS NULL OR NEW.affiliate_code = '' THEN
        NEW.affiliate_code := generate_affiliate_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_user_affiliate_code
BEFORE INSERT ON public.users
FOR EACH ROW
EXECUTE FUNCTION set_affiliate_code();

-- ==========================================
-- ВКЛЮЧЕНИЕ ROW LEVEL SECURITY (Опционально)
-- ==========================================
-- Раскомментируйте для включения RLS:

-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.whatsapp_accounts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.account_logs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- ГОТОВО! ✅
-- ==========================================
```

### 2.4 Проверка Создания Таблиц

В SQL Editor выполните:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

Должны увидеть 5 таблиц:
- ✅ users
- ✅ whatsapp_accounts
- ✅ account_logs
- ✅ payments
- ✅ withdrawals

---

## 3. Получение Crypto Pay Token

### 3.1 Создание Crypto Pay Бота

1. Откройте Telegram
2. Найдите бота **@CryptoBot**
3. Отправьте команду `/start`
4. Отправьте команду `/api`
5. Нажмите **"Create App"**
6. Введите имя приложения (например, `Atlantis Grev`)
7. Скопируйте **API Token** - это ваш `CryptoPay.Token`

### 3.2 Настройка Webhook (После запуска API)

После запуска Backend API:
```bash
# В @CryptoBot отправьте:
/api

# Выберите ваше приложение
# Нажмите "Set Webhook URL"
# Введите:
https://your-domain.com/api/accounts/webhook/payment

# Замените your-domain.com на ваш реальный домен
```

---

## 4. Настройка Backend API

### 4.1 Клонирование Проекта (если еще не сделали)

```bash
git clone https://github.com/ARTEMKOPIK/MAX-PROGREV-NEW.git
cd MAX-PROGREV-NEW/atlantis-grev/backend/AtlantisGrev.API
```

### 4.2 Конфигурация appsettings.json

Откройте файл `appsettings.json` и замените значения:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Supabase": {
    "Url": "https://xxxxxxxxxxxxx.supabase.co",  // ← Ваш Project URL
    "AnonKey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  // ← Ваш anon public ключ
  },
  "CryptoPay": {
    "Token": "12345:AAHdqTcvbXXXXXXXXXX"  // ← Ваш Crypto Pay Token
  },
  "Jwt": {
    "Secret": "YourSuperSecretKeyThatIsAtLeast32CharactersLong!",  // ← Придумайте секретный ключ (минимум 32 символа)
    "Issuer": "AtlantisGrev",
    "Audience": "AtlantisGrevUsers",
    "ExpirationDays": "7"
  },
  "App": {
    "BaseUrl": "http://localhost:8080"  // ← Замените на production URL при деплое
  },
  "WarmingService": {
    "Url": "http://localhost:5001"  // ← URL Warming Service
  }
}
```

### 4.3 Установка Зависимостей

```bash
dotnet restore
```

### 4.4 Сборка Проекта

```bash
# Development:
dotnet build

# Production:
dotnet publish -c Release -o ./publish
```

---

## 5. Настройка Warming Service

### 5.1 Перейти в Директорию

```bash
cd ../../warming-service/AtlantisGrev.WarmingService
```

### 5.2 Установка Зависимостей

```bash
dotnet restore
```

### 5.3 Настройка (опционально)

В файле `Program.cs` можно изменить:
- `MAX_CONCURRENT_SESSIONS` - количество одновременных сессий
- Chrome путь (если нестандартная установка)

### 5.4 Сборка

```bash
dotnet build
```

---

## 6. Настройка Mobile App

### 6.1 Перейти в Директорию

```bash
cd ../../mobile/atlantis_grev_mobile
```

### 6.2 Установка Flutter Зависимостей

```bash
flutter pub get
```

### 6.3 Настройка API URL

Откройте файл `lib/services/api_service.dart` и измените:

```dart
class ApiService {
  // Для локальной разработки:
  static const String baseUrl = 'http://localhost:8080';
  
  // Для Android эмулятора:
  // static const String baseUrl = 'http://10.0.2.2:8080';
  
  // Для реального устройства в локальной сети:
  // static const String baseUrl = 'http://192.168.1.XXX:8080';  // Замените XXX на IP вашего ПК
  
  // Для production:
  // static const String baseUrl = 'https://api.your-domain.com';
```

**Как узнать IP вашего ПК для тестирования на реальном устройстве:**

Windows:
```powershell
ipconfig
# Найдите "IPv4 Address" вашего сетевого адаптера
```

Linux/Mac:
```bash
ifconfig
# или
ip addr show
# Найдите inet адрес вашего сетевого интерфейса
```

### 6.4 Сборка Mobile App

```bash
# Проверка проблем:
flutter doctor

# Сборка для Android:
flutter build apk --release

# Запуск на эмуляторе/устройстве:
flutter run
```

---

## 7. Запуск Проекта

### 7.1 Запуск Backend API

#### Терминал 1 (Backend API):
```bash
cd atlantis-grev/backend/AtlantisGrev.API

# Development:
dotnet run

# Production:
cd publish
dotnet AtlantisGrev.API.dll
```

API будет доступен на: `http://localhost:8080`
Swagger документация: `http://localhost:8080/swagger`

### 7.2 Запуск Warming Service

#### Терминал 2 (Warming Service):
```bash
cd atlantis-grev/warming-service/AtlantisGrev.WarmingService

dotnet run
```

Service будет доступен на: `http://localhost:5001`

### 7.3 Запуск Mobile App

#### Терминал 3 (Mobile App):
```bash
cd atlantis-grev/mobile/atlantis_grev_mobile

flutter run
```

Или откройте в Android Studio/VS Code и нажмите Run.

---

## 8. Проверка Работоспособности

### 8.1 Проверка Backend API

Откройте браузер: `http://localhost:8080/swagger`

Проверьте endpoints:
- ✅ `/api/auth/login` - доступен
- ✅ `/api/accounts/my-accounts` - доступен
- ✅ `/api/warming/status/{accountId}` - доступен

### 8.2 Проверка Базы Данных

В Supabase перейдите в **Table Editor** и проверьте:
- ✅ Таблица `users` пустая (нормально)
- ✅ Таблица `whatsapp_accounts` пустая (нормально)

### 8.3 Тестирование через Mobile App

1. Запустите приложение
2. На экране Login введите:
   - **Telegram ID**: `123456789` (любое число)
   - **Username**: `testuser`
   - **Referral Code**: (оставьте пустым)
3. Нажмите **Login**

Если все работает:
- ✅ Вы увидите DashboardScreen
- ✅ В Supabase появится запись в таблице `users`

### 8.4 Проверка Логов

**Backend API логи:**
```
info: AtlantisGrev.API.Controllers.AuthController[0]
      Login attempt for Telegram ID: 123456789
info: AtlantisGrev.API.Controllers.AuthController[0]
      User created successfully
```

**Warming Service логи:**
```
info: AtlantisGrev.WarmingService.WarmingWorker[0]
      Warming worker started
info: AtlantisGrev.WarmingService.WarmingWorker[0]
      Listening for warming requests...
```

---

## 🎯 Готово! Проект Запущен!

Теперь вы можете:
- ✅ Регистрировать пользователей через мобильное приложение
- ✅ Покупать аккаунты через Crypto Pay
- ✅ Управлять прогревом аккаунтов
- ✅ Просматривать статистику и рефералов

---

## 🐛 Решение Проблем

### Проблема: Backend API не запускается

```bash
# Проверьте версию .NET:
dotnet --version
# Должно быть 8.0.x

# Проверьте логи:
dotnet run --verbosity detailed
```

### Проблема: Ошибка подключения к Supabase

1. Проверьте правильность URL и AnonKey
2. Убедитесь, что Supabase проект активен
3. Проверьте таблицы в Supabase Table Editor

### Проблема: Mobile App не подключается к API

1. Проверьте правильность `baseUrl` в `api_service.dart`
2. Для Android эмулятора используйте `http://10.0.2.2:8080`
3. Для реального устройства используйте IP адрес ПК
4. Убедитесь, что Backend API запущен

### Проблема: Crypto Pay не работает

1. Проверьте правильность токена в `appsettings.json`
2. Убедитесь, что webhook URL настроен в @CryptoBot
3. Для локального тестирования используйте ngrok:
```bash
ngrok http 8080
# Используйте ngrok URL для webhook
```

---

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте логи всех компонентов
2. Убедитесь, что все зависимости установлены
3. Проверьте конфигурационные файлы
4. Создайте issue на GitHub

---

**Приятного использования Atlantis Grev! 🎉**

