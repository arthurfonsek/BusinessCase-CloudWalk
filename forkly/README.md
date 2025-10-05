# Forkly — Cross-Platform Restaurant Discovery and Referral MVP

Forkly is a cross-platform restaurant discovery application built with Flutter (frontend) and Django (backend). It demonstrates a member‑get‑member growth model with referral tracking, gamification, and an AI assistant for insights.

## Technologies

### Frontend
- Flutter
- Dart
- Google Maps integration
- Material Design UI

### Backend
- Django
- Django REST Framework
- SQLite (development) / PostgreSQL (production)
- JWT authentication (Simple JWT)
- Redis caching (optional)

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Web | Supported | Chrome with Google Maps |
| Linux Desktop | Supported | Native windowed UI |
| Android | Compatible | Single codebase |
| iOS | Compatible | Single codebase |

## Features

### Maps and Search
- Google Maps integration
- Real-time restaurant search and filters (by location and category)
- Distance-aware sorting and interactive markers

### Reviews
- Restaurant detail view
- Star ratings (1–5) and user comments

### Lists
- Personal lists ("My Lists")
- Unique share codes and full CRUD for list items

### Referral Program
- Registration with referral code
- Tracking for clicks/installs/registrations/first review
- Points ledger for inviter incentives
- Invite link generation and sharing

### Gamification and Rewards
- User tiers, achievements, rewards, and points ledger
- Gamification statistics endpoint for dashboards
- Notification system for milestones

### AI Assistant and Insights
- In-app AI chat with personas (user and restaurant owner)
- Personalized recommendations and basic performance summaries
- Restaurant performance forecasting and ROI analysis

### Restaurants and Reservations
- Restaurant profiles, analytics, and owner dashboard
- Reservation creation and status updates
- Restaurant owner dashboard with metrics

## Project Structure

```
forkly/
├── backend/                 # Django API
│   ├── api/                 # Main app
│   │   ├── middleware.py    # Security middleware
│   │   ├── security.py     # Security utilities
│   │   └── models.py       # Data models
│   ├── server/              # Django settings
│   ├── db.sqlite3           # SQLite database
│   ├── env.example          # Environment template
│   └── seed_demo_data.py    # Demo seed script
├── frontend/
│   └── forkly/              # Flutter app
│       ├── lib/
│       │   ├── src/
│       │   │   ├── screens/     # App screens
│       │   │   ├── services/    # API services
│       │   │   └── app.dart     # App configuration
│       │   └── main.dart        # Entry point
│       ├── pubspec.yaml         # Flutter dependencies
│       └── demo_build.sh        # Demo helper script
└── README.md
```

## Getting Started

### 1. Backend (Django)
```bash
cd forkly/backend
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

pip install -r requirements.txt
python3 manage.py migrate
python3 seed_demo_data.py  # Seed demo data (optional)
python3 manage.py runserver
```

### 2. Frontend (Flutter)
```bash
cd forkly/frontend/forkly
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### 3. Multi-Platform Demo
```bash
cd forkly/frontend/forkly
chmod +x demo_build.sh
./demo_build.sh
```

## Security Implementation

### Authentication and Authorization
- JWT-based authentication with token rotation
- Role-based access control (user, restaurant_owner, admin)
- Password validation and secure storage
- Session management with secure cookies

### API Security
- Rate limiting (60 requests/minute per IP, 100 requests/hour per user)
- Input validation and sanitization
- XSS and SQL injection prevention
- Security headers on all responses

### Data Protection
- Environment-based configuration
- Secure secret management
- Data validation and sanitization
- Audit logging for security events

### Production Security
- HTTPS enforcement
- CORS configuration
- Content Security Policy
- Brute force protection

## Scalability Features

### Database Optimization
- Connection pooling for production
- Query optimization with select_related/prefetch_related
- Database indexing for location queries
- Support for PostgreSQL in production

### Caching Strategy
- Redis caching for sessions and data
- Intelligent cache TTL based on data type
- Cache invalidation strategies
- Performance monitoring

### API Performance
- Response compression
- Efficient pagination
- Rate limiting with token bucket algorithm
- Request/response logging

## Environment Configuration

### Development Setup
```bash
# Copy environment template
cp env.example .env

# Configure development settings
DJANGO_SECRET=your-development-secret
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
ALLOWED_ORIGINS=http://localhost:43495
```

### Production Setup
```bash
# Production environment variables
DJANGO_SECRET=your-super-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,api.yourdomain.com
ALLOWED_ORIGINS=https://yourdomain.com
DATABASE_URL=postgresql://user:pass@localhost:5432/forkly_db
REDIS_URL=redis://localhost:6379/0
```

## Demo Data

Included demo content:
- 26 restaurants near São Paulo
- 5 demo users with referral codes
- 16 sample reviews
- 8 user lists with 24 items
- 5 tracked referral events

## Development Requirements

- Flutter SDK 3.35.5+
- Dart SDK 3.9.2+
- Python 3.10+
- Django 5.2.7+
- Chrome (for web)

## Business Metrics (Demo)

- AI assistance success rate: 78.5% (target ≥ 70%)
- Referral funnel: 15 clicked → 8 registered → 5 first review
- Conversion rate: 33.3%
- Cross-platform compatibility: 100%

## Security Best Practices

### Input Validation
All user inputs are validated and sanitized to prevent XSS and injection attacks. The system includes comprehensive validation for:
- Email addresses and usernames
- Geographic coordinates
- Search queries
- Referral codes

### Rate Limiting
The application implements intelligent rate limiting:
- Per-IP rate limiting with burst capacity
- Per-user rate limiting for authenticated users
- Different limits for different user tiers
- Automatic lockout for excessive requests

### Monitoring and Logging
- Structured logging for all security events
- Failed login attempt tracking
- Rate limiting violation logging
- Performance metrics collection

## Production Deployment

### Security Checklist
- All secrets configured via environment variables
- HTTPS enabled and properly configured
- Rate limiting tested and configured
- Security headers verified
- Database encryption enabled
- Logging and monitoring configured

### Performance Optimization
- Database connection pooling
- Redis caching configured
- Static file optimization
- API response compression
- Query optimization

## License

This project is a technical demonstration for educational purposes.
