# 🚀 Atlantis Grev - Deployment Guide

Complete step-by-step guide to deploy all components of the Atlantis Grev system.

## 📋 Prerequisites

### Required Software
- **.NET 8.0 SDK** - For Backend API and Warming Service
- **Flutter SDK 3.0+** - For Mobile Application
- **Chrome/Chromium** - For WhatsApp automation
- **PostgreSQL** (via Supabase) - Database
- **Git** - Version control

### Required Accounts
- **Supabase** account with project created
- **Crypto Pay** API token
- **Firebase** project (for push notifications)

## 🔧 Component 1: Backend API

### Step 1: Configure Environment

Navigate to backend directory:
```bash
cd atlantis-grev/backend/AtlantisGrev.API
```

Update `appsettings.json` with your credentials:
```json
{
  "Supabase": {
    "Url": "YOUR_SUPABASE_URL",
    "AnonKey": "YOUR_SUPABASE_ANON_KEY"
  },
  "CryptoPay": {
    "Token": "YOUR_CRYPTOPAY_TOKEN"
  },
  "Jwt": {
    "Secret": "YOUR_JWT_SECRET_KEY_AT_LEAST_32_CHARS",
    "Issuer": "AtlantisGrev",
    "ExpirationDays": "7"
  },
  "WarmingService": {
    "Url": "http://localhost:5001"
  }
}
```

### Step 2: Install Dependencies

```bash
dotnet restore
```

### Step 3: Build & Run

Development:
```bash
dotnet run
```

Production:
```bash
dotnet publish -c Release -o ./publish
cd publish
dotnet AtlantisGrev.API.dll
```

The API will be available at `http://localhost:5000` (or configured port).

### Step 4: Verify API

Open browser and navigate to:
- `http://localhost:5000/swagger` - API Documentation
- Test endpoints using Swagger UI

---

## 🔄 Component 2: Warming Service

### Step 1: Navigate to Service Directory

```bash
cd atlantis-grev/warming-service/AtlantisGrev.WarmingService
```

### Step 2: Install Dependencies

```bash
dotnet restore
```

### Step 3: Configure Environment Variables

Set environment variables (optional, defaults provided):
```bash
export BACKEND_API_URL="http://localhost:5000"
export MAX_CONCURRENT_JOBS="5"
```

Or create `.env` file:
```
BACKEND_API_URL=http://localhost:5000
MAX_CONCURRENT_JOBS=5
```

### Step 4: Install Chrome

The service requires Chrome/Chromium for automation:

**Linux:**
```bash
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
apt-get update
apt-get install google-chrome-stable
```

**macOS:**
```bash
brew install --cask google-chrome
```

### Step 5: Build & Run

Development:
```bash
dotnet run
```

Production:
```bash
dotnet publish -c Release -o ./publish
cd publish
dotnet AtlantisGrev.WarmingService.dll
```

The service will listen on port 5001 for warming requests.

---

## 📱 Component 3: Mobile Application

### Step 1: Install Flutter

Follow official guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### Step 2: Navigate to Mobile Directory

```bash
cd atlantis-grev/mobile/atlantis_grev_mobile
```

### Step 3: Configure API URL

Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com';
// For local testing: 'http://localhost:5000'
// For Android emulator: 'http://10.0.2.2:5000'
```

### Step 4: Install Dependencies

```bash
flutter pub get
```

### Step 5: Configure Firebase (Optional)

1. Create Firebase project at https://console.firebase.google.com
2. Add Android app:
   - Download `google-services.json`
   - Place in `android/app/`
3. Add iOS app:
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

### Step 6: Run Application

Development (with hot reload):
```bash
flutter run
```

Build for Android:
```bash
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

Build for iOS:
```bash
flutter build ios --release
# Open in Xcode for signing and distribution
```

---

## 🗄️ Database Setup

### Step 1: Create Supabase Project

1. Go to https://supabase.com
2. Create new project
3. Note your URL and anon key

### Step 2: Run SQL Schema

In Supabase SQL Editor, execute:

```sql
-- Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username TEXT NOT NULL,
    paid_accounts INT DEFAULT 0,
    referrals INT DEFAULT 0,
    registration_date TIMESTAMP DEFAULT NOW(),
    referrer_id BIGINT REFERENCES users(id),
    phone_numbers TEXT[],
    affiliate_balance DECIMAL(10, 2) DEFAULT 0,
    total_earned DECIMAL(10, 2) DEFAULT 0,
    affiliate_code TEXT UNIQUE NOT NULL
);

-- Payments table
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    hash TEXT UNIQUE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    asset TEXT DEFAULT 'USDT',
    status TEXT DEFAULT 'pending',
    accounts_count INT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- WhatsApp Accounts table
CREATE TABLE whatsapp_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT REFERENCES users(id),
    phone_number TEXT NOT NULL,
    status TEXT DEFAULT 'Idle',
    warming_status TEXT DEFAULT 'NotStarted',
    session_dir TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    warming_started_at TIMESTAMP,
    warming_completed_at TIMESTAMP,
    warming_progress INT DEFAULT 0,
    warming_logs TEXT[]
);

-- Indexes
CREATE INDEX idx_users_affiliate_code ON users(affiliate_code);
CREATE INDEX idx_users_referrer_id ON users(referrer_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_hash ON payments(hash);
CREATE INDEX idx_accounts_user_id ON whatsapp_accounts(user_id);
CREATE INDEX idx_accounts_warming_status ON whatsapp_accounts(warming_status);
```

---

## 🌐 Production Deployment

### Backend API Deployment

**Recommended: Docker**
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY ./publish .
ENTRYPOINT ["dotnet", "AtlantisGrev.API.dll"]
```

Build and run:
```bash
docker build -t atlantisgrev-api .
docker run -p 5000:5000 atlantisgrev-api
```

**Alternative: Direct VPS**
1. Upload published files to server
2. Install .NET 8.0 Runtime
3. Setup systemd service:

```ini
[Unit]
Description=Atlantis Grev API

[Service]
WorkingDirectory=/var/www/atlantisgrev-api
ExecStart=/usr/bin/dotnet /var/www/atlantisgrev-api/AtlantisGrev.API.dll
Restart=always
RestartSec=10
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable atlantisgrev-api
sudo systemctl start atlantisgrev-api
```

### Warming Service Deployment

Similar process, but ensure Chrome is installed on server:
```bash
apt-get install google-chrome-stable
```

Systemd service:
```ini
[Unit]
Description=Atlantis Grev Warming Service

[Service]
WorkingDirectory=/var/www/atlantisgrev-warming
ExecStart=/usr/bin/dotnet /var/www/atlantisgrev-warming/AtlantisGrev.WarmingService.dll
Restart=always
RestartSec=10
User=warming-service
Environment=BACKEND_API_URL=http://localhost:5000

[Install]
WantedBy=multi-user.target
```

### Mobile App Deployment

**Google Play Store:**
1. Build signed APK/AAB
2. Create Play Console account
3. Upload app bundle
4. Complete store listing

**Apple App Store:**
1. Build iOS app with certificates
2. Upload to App Store Connect
3. Complete app review process

---

## 🔒 Security Checklist

- [ ] Change all default passwords and secrets
- [ ] Use strong JWT secret (minimum 32 characters)
- [ ] Enable HTTPS/TLS for API
- [ ] Configure CORS properly (whitelist domains)
- [ ] Set up firewall rules
- [ ] Enable rate limiting
- [ ] Configure Supabase Row Level Security
- [ ] Validate Crypto Pay webhook signatures
- [ ] Regular security updates
- [ ] Monitor logs for suspicious activity

---

## 📊 Monitoring

### Backend API Logs
```bash
# View real-time logs
tail -f /var/log/atlantisgrev-api.log

# Check systemd logs
journalctl -u atlantisgrev-api -f
```

### Warming Service Logs
```bash
# View real-time logs
tail -f /var/log/atlantisgrev-warming.log

# Check systemd logs
journalctl -u atlantisgrev-warming -f
```

### Database Monitoring
- Use Supabase dashboard for query performance
- Monitor table sizes and index usage
- Set up alerts for slow queries

---

## 🔧 Troubleshooting

### Backend API won't start
- Check .NET 8.0 is installed: `dotnet --version`
- Verify appsettings.json is correct
- Check port 5000 is not in use: `netstat -tlnp | grep 5000`
- Review logs for errors

### Warming Service crashes
- Ensure Chrome is installed: `google-chrome --version`
- Check Backend API is reachable
- Verify sufficient disk space for sessions
- Check memory usage (Chrome can be memory-intensive)

### Mobile app can't connect
- Verify API URL is correct
- Check API is accessible from mobile network
- For Android emulator, use `10.0.2.2` instead of `localhost`
- Check CORS configuration on backend

### Database connection fails
- Verify Supabase URL and anon key
- Check network connectivity
- Ensure Supabase project is active
- Review API keys permissions

---

## 📞 Support

For issues or questions:
- Check documentation first
- Review logs for error messages
- Consult architecture documentation
- Contact development team

---

**Deployment completed! Your Atlantis Grev system is ready to serve users.** 🎉

