# 📈 NEPSE Tracker — Flutter App

A modern dark-themed Flutter mobile app for tracking Nepal Stock Exchange (NEPSE) data including IPO/FPO, Right Shares, Bonus Shares, Promoter Unlock, Live Prices, and Floorsheet/Broker Activity.

---

## 🚀 Features

| Feature | Description |
|---|---|
| 📊 **NEPSE Index** | Live market index with open/closed status, turnover, transactions |
| 🚀 **IPO / FPO Tracker** | Open and upcoming public issues with dates, price, units |
| 💼 **Right Shares** | Active right share issuances with ratio, open/close dates |
| 🎁 **Bonus Shares** | Stock bonus, cash dividend, and credit bonus tracker |
| 🔓 **Promoter Share Unlock** | Lock-in expiry dates, units unlocking, days remaining |
| 📈 **Live Stock Prices** | Real-time LTP, change %, volume — searchable & filterable by sector |
| 📋 **Floorsheet** | Per-symbol transaction history — buyer broker, seller broker, qty, rate |
| 🏢 **Broker Activity** | Aggregated buy/sell/net position per broker for any symbol |

---

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android or iOS device / emulator

### Installation

```bash
# 1. Navigate to project
cd nepse_app

# 2. Install dependencies
flutter pub get

# 3. Run on device/emulator
flutter run

# 4. Build APK (Android)
flutter build apk --release

# 5. Build for iOS
flutter build ios --release
```

---

## 📡 API Integration

The app uses a layered data strategy:

### Primary: Official NEPSE API
```
Base URL: https://www.nepalstock.com/api/nots/
```
Endpoints used:
- `GET /market-open` — Market summary & NEPSE index
- `GET /public-issue/open-public-issue` — Active IPOs
- `GET /public-issue/upcoming-public-issue` — Upcoming IPOs
- `GET /rights-share/open` — Active right shares
- `GET /bonus-share/announced` — Declared bonuses
- `POST /security/floorsheet` — Floorsheet transactions
- `GET /market/securities/headings` — Live stock prices

### Fallback: Scraped Data
If official APIs are unavailable, the app falls back to realistic mock data so the UI always renders.

### To connect real scraping (for corporate events):
- **merolagani.com/AnnouncementList.aspx** — All corporate announcements
- **sebon.gov.np/right-share-pipeline** — SEBON right share pipeline
- **sharesansar.com/events** — Dividend/bonus events

> ⚠️ For production scraping, build a Node.js/Python backend proxy to scrape these sites and serve JSON to the Flutter app. This avoids CORS issues on mobile.

---

## 🏗️ Project Structure

```
lib/
├── main.dart                     # App entry point
├── theme/
│   └── app_theme.dart            # Dark theme, colors, typography
├── models/
│   └── models.dart               # Data models (IPO, Stock, Bonus, etc.)
├── services/
│   └── nepse_api_service.dart    # API calls + mock data fallback
├── widgets/
│   └── common_widgets.dart       # Reusable UI components
└── screens/
    ├── home_screen.dart          # Dashboard + quick actions
    ├── stock_list_screen.dart    # Live market prices
    ├── ipo_screen.dart           # IPO/FPO tracker
    ├── right_share_screen.dart   # Right shares + Bonus + Promoter
    └── floorsheet_screen.dart    # Floorsheet + Broker activity
```

---

## 🔮 Next Steps / Roadmap

- [ ] **Push Notifications** — Alert when IPO opens, bonus declared, promoter unlock approaching
- [ ] **Portfolio Tracker** — Enter your holdings, track P&L
- [ ] **Price Alerts** — Set target price for any stock
- [ ] **Meroshare Integration** — Check applied IPOs, EDIS status
- [ ] **Company Detail Page** — Financial statements, dividend history, right share history
- [ ] **Chart** — Candlestick/line chart for historical prices
- [ ] **Backend API** — Node.js/Python scraper for merolagani + sharesansar
- [ ] **Widget** — Home screen widget showing NEPSE index

---

## 📦 Dependencies

```yaml
http: ^1.2.0               # API calls
shimmer: ^3.0.0            # Loading skeleton
fl_chart: ^0.68.0          # Charts (future use)
google_fonts: ^6.2.1       # Inter font
provider: ^6.1.2           # State management
shared_preferences: ^2.2.2 # Local storage
flutter_local_notifications # Push alerts
intl: ^0.19.0              # Number/date formatting
```

---

## ⚖️ Disclaimer

This app uses publicly available data from NEPSE and related portals for educational and informational purposes. For commercial use of NEPSE data, obtain a license from Nepal Stock Exchange.
