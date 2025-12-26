# 🏛️ Atlantis Grev - Architecture Documentation

## System Overview

Atlantis Grev is a distributed system consisting of three main components that work together to provide WhatsApp account warming services through a modern mobile application interface.

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile Application                       │
│                      (Flutter/Dart)                          │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐    │
│  │   Auth     │  │   Accounts   │  │   Referrals     │    │
│  │  Screens   │  │   Screens    │  │    Screens      │    │
│  └────────────┘  └──────────────┘  └─────────────────┘    │
│         │                │                    │             │
│         └────────────────┴────────────────────┘             │
│                          │                                  │
│                     REST API                                │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     Backend API Server                       │
│                    (ASP.NET Core 8.0)                        │
│  ┌────────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ Authentication │  │   Accounts   │  │   Referrals   │  │
│  │   Controller   │  │  Controller  │  │  Controller   │  │
│  └────────┬───────┘  └──────┬───────┘  └───────┬───────┘  │
│           │                  │                   │          │
│           └──────────────────┴───────────────────┘          │
│                              │                              │
│           ┌──────────────────┴──────────────────┐          │
│           │                                     │          │
│    ┌──────▼────────┐                    ┌──────▼───────┐  │
│    │   Supabase    │                    │  Crypto Pay  │  │
│    │   Service     │                    │   Service    │  │
│    └──────┬────────┘                    └──────────────┘  │
│           │                                                │
└───────────┼────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Supabase Database                       │
│                       (PostgreSQL)                           │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐    │
│  │   users    │  │   payments   │  │ whatsapp_accts  │    │
│  └────────────┘  └──────────────┘  └─────────────────┘    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Warming Service                           │
│                (ASP.NET Core Console App)                    │
│  ┌──────────────────────────────────────────────────┐      │
│  │           Chrome DevTools Protocol                │      │
│  │           WhatsApp Web Automation                 │      │
│  │          Queue-based Job Processing               │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Mobile Application (Flutter)

#### Technology Stack
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Riverpod
- **HTTP Client**: Dio with Retrofit
- **Local Storage**: flutter_secure_storage, shared_preferences
- **Push Notifications**: Firebase Cloud Messaging
- **UI Components**: Material Design 3

#### Architecture Pattern
Clean Architecture with feature-based organization:

```
lib/
├── models/           # Data models
├── services/         # API and business logic services
├── screens/          # UI screens
├── widgets/          # Reusable UI components
├── providers/        # Riverpod providers
├── routes/           # Navigation
└── utils/            # Helper functions and constants
```

#### Key Features
1. **Authentication Flow**
   - Telegram ID-based login
   - JWT token storage in secure storage
   - Automatic token refresh

2. **Real-time Updates**
   - WebSocket connection for live warming progress
   - Pull-to-refresh for manual updates
   - Push notifications for major events

3. **Offline Support**
   - Local caching of user data
   - Queued actions when offline
   - Sync when connection restored

### 2. Backend API (ASP.NET Core)

#### Technology Stack
- **Framework**: ASP.NET Core 8.0
- **Language**: C# 12
- **Authentication**: JWT Bearer Tokens
- **Database Client**: HTTP Client (REST)
- **API Documentation**: Swagger/OpenAPI

#### Architecture Pattern
Layered Architecture:

```
AtlantisGrev.API/
├── Controllers/      # API endpoints
├── Services/         # Business logic
├── Models/           # Domain models
├── DTOs/             # Data transfer objects
└── Middleware/       # Custom middleware
```

#### Core Services

1. **SupabaseService**
   - Database abstraction layer
   - CRUD operations for all entities
   - Transaction management

2. **CryptoPayService**
   - Invoice creation
   - Payment verification
   - Transfer/withdrawal processing

3. **AuthService**
   - JWT token generation
   - Token validation
   - User claims management

#### API Design Principles
- RESTful conventions
- Consistent error responses
- Versioned endpoints
- Rate limiting
- Request validation

### 3. Warming Service (Microservice)

#### Technology Stack
- **Framework**: ASP.NET Core Console
- **Browser Automation**: Chrome DevTools Protocol
- **Queue System**: In-memory queue (can be upgraded to RabbitMQ)
- **Communication**: HTTP webhooks to Backend API

#### Architecture
Event-driven microservice:

```
AtlantisGrev.WarmingService/
├── MaxWebAutomation.cs   # Chrome automation
├── QueueManager.cs        # Job queue management
├── WarmingWorker.cs       # Background worker
└── ApiClient.cs           # Backend API client
```

#### Warming Process Flow
1. Backend API adds account to warming queue
2. Warming service picks up job from queue
3. Chrome instance launched with account session
4. Automated actions performed (messages, status updates, etc.)
5. Progress updates sent to Backend API
6. Status changes trigger mobile push notifications

#### Scalability Considerations
- Multiple worker threads
- Horizontal scaling possible
- Session isolation
- Resource management

## Data Flow Diagrams

### Account Purchase Flow

```
Mobile App          Backend API         Crypto Pay          Supabase
    |                   |                    |                  |
    |---Purchase------->|                    |                  |
    |                   |---CreateInvoice--->|                  |
    |                   |<--InvoiceURL-------|                  |
    |                   |                    |                  |
    |                   |---SavePayment---------------->        |
    |<--InvoiceURL------|                    |                  |
    |                   |                    |                  |
User pays invoice      |                    |                  |
    |                   |                    |                  |
    |                   |<--Webhook----------|                  |
    |                   |                    |                  |
    |                   |---CreateAccounts------------>         |
    |                   |---UpdateBalance------------->         |
    |                   |                    |                  |
    |<--Notification----|                    |                  |
```

### Warming Process Flow

```
Mobile App       Backend API      Warming Service     Chrome/WhatsApp
    |                |                   |                    |
    |--StartWarm---->|                   |                    |
    |                |---QueueJob------->|                    |
    |<--Queued-------|                   |                    |
    |                |                   |                    |
    |                |                   |---LaunchChrome---->|
    |                |                   |                    |
    |                |                   |---LoadSession----->|
    |                |                   |<--Ready------------|
    |                |                   |                    |
    |                |<--StatusUpdate----|                    |
    |<--PushNotif----|                   |                    |
    |                |                   |                    |
    |                |                   |---SendMessages---->|
    |                |                   |<--Sent-------------|
    |                |<--Progress(25%)----|                   |
    |<--Update-------|                   |                    |
    |                |                   |                    |
    |                |                   |---UpdateStatus---->|
    |                |                   |<--Updated----------|
    |                |<--Progress(50%)----|                   |
    |<--Update-------|                   |                    |
    |                |                   |                    |
    |                |                   | ... continues ...  |
    |                |                   |                    |
    |                |<--Completed(100%)-|                    |
    |<--PushNotif----|                   |                    |
```

## Security Architecture

### Authentication & Authorization

1. **JWT-Based Authentication**
   - Access tokens valid for 7 days
   - Refresh tokens for extended sessions
   - Token stored in secure storage on mobile

2. **API Security**
   - All endpoints require authentication (except webhooks)
   - Role-based access control
   - Rate limiting per user
   - Request validation

3. **Data Protection**
   - HTTPS only
   - Encrypted database connections
   - Secure credential storage
   - No sensitive data in logs

### Webhook Security

1. **Payment Webhooks**
   - Signature validation (to be implemented)
   - Idempotency checks
   - IP whitelist (recommended)

## Database Design

### Entity Relationships

```
users
  ├── one-to-many: payments
  ├── one-to-many: whatsapp_accounts
  ├── one-to-many: withdrawals
  └── one-to-many: referrals (self-referential)

payments
  └── many-to-one: users

whatsapp_accounts
  └── many-to-one: users
```

### Indexes

```sql
-- Users table
CREATE INDEX idx_users_affiliate_code ON users(affiliate_code);
CREATE INDEX idx_users_referrer_id ON users(referrer_id);

-- Payments table
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_hash ON payments(hash);
CREATE INDEX idx_payments_status ON payments(status);

-- WhatsApp Accounts table
CREATE INDEX idx_accounts_user_id ON whatsapp_accounts(user_id);
CREATE INDEX idx_accounts_warming_status ON whatsapp_accounts(warming_status);
CREATE INDEX idx_accounts_status ON whatsapp_accounts(status);
```

## Scaling Considerations

### Horizontal Scaling

1. **Backend API**
   - Stateless design enables easy scaling
   - Load balancer distribution
   - Session-less architecture

2. **Warming Service**
   - Multiple instances possible
   - Queue-based job distribution
   - Independent session management

### Vertical Scaling

1. **Database**
   - Supabase handles scaling automatically
   - Connection pooling
   - Read replicas for heavy reads

2. **Cache Layer** (Future)
   - Redis for session caching
   - Reduced database load
   - Faster response times

## Monitoring & Observability

### Logging Strategy

1. **Application Logs**
   - Structured logging (JSON)
   - Log levels: Debug, Info, Warning, Error
   - User action tracking

2. **Warming Logs**
   - Detailed automation logs
   - Stored in database
   - Accessible via mobile app

3. **Error Tracking**
   - Exception logging
   - Stack traces
   - User context

### Metrics (Planned)

- API request latency
- Warming success rate
- Active users
- Payment conversion rate
- System resource usage

## Deployment Architecture

### Recommended Setup

```
                    ┌──────────────┐
                    │ Load Balancer │
                    └───────┬──────┘
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
    ┌─────▼─────┐                      ┌─────▼─────┐
    │  Backend  │                      │  Backend  │
    │  API #1   │                      │  API #2   │
    └─────┬─────┘                      └─────┬─────┘
          │                                   │
          └─────────────────┬─────────────────┘
                            │
                    ┌───────▼────────┐
                    │   Supabase     │
                    │   Database     │
                    └────────────────┘

    ┌──────────────┐         ┌──────────────┐
    │  Warming     │         │  Warming     │
    │  Service #1  │         │  Service #2  │
    └──────────────┘         └──────────────┘
```

### Environment Configuration

1. **Development**
   - Local .NET runtime
   - Local Flutter development
   - Supabase cloud database

2. **Staging**
   - Docker containers
   - CI/CD pipeline
   - Staging database

3. **Production**
   - Kubernetes cluster (recommended)
   - Auto-scaling enabled
   - Production database with backups

## Future Enhancements

### Phase 2
- [ ] WebSocket for real-time updates
- [ ] Advanced warming strategies
- [ ] Account quality scoring
- [ ] Multi-language support

### Phase 3
- [ ] Admin dashboard
- [ ] Analytics platform
- [ ] A/B testing framework
- [ ] Machine learning for optimization

### Phase 4
- [ ] Multi-region deployment
- [ ] CDN integration
- [ ] Advanced security features
- [ ] Blockchain integration

---

**Last Updated**: 2024
**Version**: 1.0.0
**Maintained By**: ARTEMKOPIK

