# 🌊 Atlantis Grev - WhatsApp Account Warming System

Modern mobile application and backend API for automated WhatsApp account warming service with cryptocurrency payment integration.

## 📋 Project Overview

Atlantis Grev is a complete rewrite and modernization of the MAX-PROGREV Telegram bot, transforming it into a professional mobile application with superior UX/UI design. The system allows users to purchase WhatsApp accounts and automatically warm them up through an automated warming process, all managed through a beautiful Flutter mobile application.

## 🏗️ Architecture

The project consists of three main components:

### 1. Backend API (ASP.NET Core 8.0)
- **Location**: `backend/AtlantisGrev.API/`
- **Purpose**: RESTful API serving both mobile app and legacy Telegram bot
- **Tech Stack**: 
  - ASP.NET Core 8.0
  - JWT Authentication
  - Supabase (PostgreSQL Database)
  - Crypto Pay API Integration
- **Key Features**:
  - User authentication and registration
  - Account purchase and management
  - Warming process control
  - Referral/affiliate program
  - Withdrawal processing

### 2. Warming Service (ASP.NET Core Console)
- **Location**: `warming-service/AtlantisGrev.WarmingService/`
- **Purpose**: Microservice handling WhatsApp automation
- **Tech Stack**:
  - Chrome DevTools Protocol
  - WebSocket connections
  - Queue-based processing
- **Key Features**:
  - Multiple concurrent warming sessions
  - Real-time status updates
  - Detailed logging
  - Graceful pause/resume/stop

### 3. Mobile Application (Flutter)
- **Location**: `mobile/atlantis_grev_mobile/`
- **Purpose**: Cross-platform mobile app for end users
- **Tech Stack**:
  - Flutter (Dart)
  - Riverpod (State Management)
  - Material Design 3
  - Firebase (Push Notifications)
- **Key Features**:
  - Modern, intuitive UI/UX
  - Real-time warming progress tracking
  - Crypto payment integration
  - Referral program management
  - Push notifications

## 🚀 Getting Started

### Prerequisites

#### For Backend API:
- .NET 8.0 SDK
- Supabase account
- Crypto Pay API token

#### For Warming Service:
- .NET 8.0 SDK
- Chrome/Chromium browser
- Linux/Windows server

#### For Mobile App:
- Flutter SDK (3.0+)
- Android Studio / Xcode
- Firebase account

### Installation & Setup

#### 1. Backend API Setup

```bash
cd atlantis-grev/backend/AtlantisGrev.API

# Restore dependencies
dotnet restore

# Update appsettings.json with your credentials
# - Supabase URL and Key
# - Crypto Pay Token
# - JWT Secret

# Run the API
dotnet run
```

The API will be available at `https://localhost:5000` (or your configured port).

#### 2. Warming Service Setup

```bash
cd atlantis-grev/warming-service/AtlantisGrev.WarmingService

# Restore dependencies
dotnet restore

# Configure connection to Backend API

# Run the service
dotnet run
```

#### 3. Mobile App Setup

```bash
cd atlantis-grev/mobile/atlantis_grev_mobile

# Get Flutter dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build

# Run the app
flutter run
```

## 📊 Database Schema

### Tables

#### users
```sql
- id (bigint, primary key)
- username (text)
- paid_accounts (int, default 0)
- referrals (int, default 0)
- registration_date (timestamp)
- referrer_id (bigint, nullable)
- phone_numbers (text[])
- affiliate_balance (decimal, default 0)
- total_earned (decimal, default 0)
- affiliate_code (text, unique)
```

#### payments
```sql
- id (bigserial, primary key)
- user_id (bigint, foreign key)
- hash (text, unique)
- amount (decimal)
- asset (text, default 'USDT')
- status (text, default 'pending')
- accounts_count (int)
- created_at (timestamp)
- completed_at (timestamp, nullable)
```

#### whatsapp_accounts
```sql
- id (uuid, primary key)
- user_id (bigint, foreign key)
- phone_number (text)
- status (text)
- warming_status (text)
- session_dir (text)
- created_at (timestamp)
- warming_started_at (timestamp, nullable)
- warming_completed_at (timestamp, nullable)
- warming_progress (int, default 0)
- warming_logs (text[])
```

## 🔐 API Endpoints

### Authentication
- `POST /api/auth/login` - User login/registration
- `POST /api/auth/refresh` - Refresh access token

### Accounts
- `POST /api/accounts/purchase` - Purchase WhatsApp accounts
- `GET /api/accounts/my-accounts` - Get user's accounts
- `GET /api/accounts/{id}` - Get account details
- `POST /api/accounts/webhook/payment` - Payment webhook

### Warming
- `POST /api/warming/start` - Start warming process
- `GET /api/warming/status/{accountId}` - Get warming status
- `POST /api/warming/action` - Pause/Resume/Stop warming
- `GET /api/warming/logs/{accountId}` - Get warming logs

### Referrals
- `GET /api/referrals/stats` - Get referral statistics
- `POST /api/referrals/withdraw` - Request withdrawal
- `GET /api/referrals/withdrawals` - Get withdrawal history

## 💰 Business Logic

### Pricing
- **Account Price**: $0.50 USDT per account
- **Referral Commission**: 10% of transaction value
- **Withdrawal Limits**: 
  - Minimum: $0.05 USDT
  - Maximum: $1000 USDT

### Warming Process
1. User purchases accounts via Crypto Pay invoice
2. Payment webhook triggers account creation
3. User initiates warming from mobile app
4. Warming service processes account through Chrome automation
5. Real-time updates sent to mobile app
6. Completion notification via push notification

### Referral System
1. Each user gets unique affiliate code
2. New users can enter referral code during registration
3. Referrer earns 10% commission on all purchases
4. Commission added to affiliate balance
5. Users can withdraw earnings to their wallet

## 🎨 Mobile App Screens

1. **Login Screen** - Telegram authentication
2. **Dashboard** - Overview of accounts and stats
3. **Account Store** - Purchase new accounts
4. **My Accounts** - List of purchased accounts
5. **Account Details** - Detailed view with warming logs
6. **Warming Control** - Start/pause/stop warming
7. **Referrals** - Affiliate program management
8. **Withdrawal** - Request earnings withdrawal
9. **Notifications** - Push notification center
10. **Profile** - User settings and information

## 🔧 Configuration

### Backend API (appsettings.json)
```json
{
  "Supabase": {
    "Url": "your-supabase-url",
    "AnonKey": "your-supabase-key"
  },
  "CryptoPay": {
    "Token": "your-cryptopay-token"
  },
  "Jwt": {
    "Secret": "your-jwt-secret",
    "Issuer": "AtlantisGrev",
    "ExpirationDays": "7"
  },
  "App": {
    "BaseUrl": "https://your-domain.com"
  },
  "WarmingService": {
    "Url": "http://localhost:5001"
  }
}
```

### Mobile App (lib/services/api_service.dart)
```dart
static const String baseUrl = 'https://api.your-domain.com';
```

## 📱 Features Roadmap

### Phase 1 ✅ (Completed)
- [x] Backend API development
- [x] Database schema design
- [x] Authentication system
- [x] Payment integration
- [x] Basic mobile app structure

### Phase 2 🚧 (In Progress)
- [ ] Warming service implementation
- [ ] Complete mobile app UI
- [ ] Firebase integration
- [ ] Push notifications
- [ ] Real-time updates

### Phase 3 📋 (Planned)
- [ ] Admin dashboard
- [ ] Analytics and reporting
- [ ] Multiple payment gateways
- [ ] Account quality scoring
- [ ] Advanced warming strategies

### Phase 4 🔮 (Future)
- [ ] iOS App Store release
- [ ] Android Play Store release
- [ ] Multi-language support
- [ ] Dark mode themes
- [ ] In-app purchases

## 🐛 Known Issues

1. Warming service not yet implemented
2. Firebase not configured
3. Payment webhook signature validation pending
4. Refresh token storage not implemented
5. Withdrawal history persistence needed

## 🤝 Contributing

This is a private project. For access or contribution inquiries, please contact the project owner.

## 📄 License

Proprietary - All rights reserved

## 👥 Team

- **Developer**: ARTEMKOPIK
- **Project**: Atlantis Grev
- **Original Bot**: MAX-PROGREV (Telegram Bot)

## 📞 Support

For support, please contact through GitHub issues or project communication channels.

---

**Built with ❤️ using ASP.NET Core, Flutter, and modern cloud technologies**

