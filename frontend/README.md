# 📱 Project PARAKH — Mobile App
## Flutter Application for Legal Metrology Field Enforcement

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue?logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API_21+-green?logo=android)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-14+-black?logo=apple)](https://developer.apple.com)

> Part of [Project PARAKH](../README.md) — Government of India

---

## 📋 Overview

The PARAKH mobile app is a **Flutter 3.x** application for field enforcement officers. It delivers:

- 📸 **AR-powered label scanning** with real-time bounding box overlays
- 🔍 **GS1 barcode verification** against Open Food Facts registry
- 🤖 **One-tap AI compliance** — OCR → NER → Rules → Anomaly Detection
- 📶 **Offline-first architecture** — works without connectivity, syncs later
- 🔐 **Biometric authentication** — fingerprint / Face ID
- 📄 **Multi-format reports** — PDF, JSON, CSV with blockchain hash
- 👥 **4 role-isolated dashboards** — Inspector, Nodal, Commissioner, Citizen

---

## 📱 Screens & Navigation

### Flow Diagram

```
App Launch
    │
    ▼
🎬 Splash Screen  (video animation, 3s)
    │
    ▼
🔑 Login Screen   (biometric / credentials)
    │
    ▼
🔀 Role Router    (RoleGuard checks JWT role)
    │
    ├─────────────────────────────────────────┐
    │                 │              │         │
    ▼                 ▼              ▼         ▼
👮 INSPECTOR      🏢 NODAL     🏛️ COMMISSIONER  👤 CITIZEN
   Dashboard        Dashboard      Dashboard     Dashboard
    │                 │              │              │
    ├─ AR Camera      ├─ Verifier    └─ Portal      └─ Verify
    ├─ Barcode        │    Queue         (Notices        Barcode
    ├─ AI Review      └─ Analytics       + Audit)
    ├─ Verdict
    ├─ Report ──► PDF / JSON / CSV + Blockchain Hash
    ├─ Intake
    ├─ History
    └─ Offline Sync
```

---

### All 18 Screens

#### 🔐 Common Screens
| # | Screen | File | Description |
|---|--------|------|-------------|
| 1 | 🎬 Splash | `splash_screen.dart` | Video animation, auto-navigate to login or dashboard |
| 2 | 🔑 Login | `login_screen.dart` | JWT auth with biometric unlock + role selection modal |
| 3 | ⚙️ Profile | `profile_settings_screen.dart` | User profile, notification prefs, biometric toggle, logout |
| 4 | 🔀 Router | `dashboard_screen.dart` | Reads role from JWT, redirects to correct dashboard |

#### 👮 Inspector Screens (9)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 5 | 📊 Dashboard | `inspector_dashboard_screen.dart` | Metrics: inspections today, violations, pending sync |
| 6 | 📸 AR Camera | `ar_camera_screen.dart` | ARCore/ARKit guided capture with live overlay boxes |
| 7 | 🔍 Barcode | `barcode_scanner_screen.dart` | GS1 scan + Open Food Facts + manual GTIN entry |
| 8 | 🤖 AI Review | `ai_review_screen.dart` | Side-by-side: original image vs AI extracted fields |
| 9 | ✅ Verdict | `compliance_verdict_screen.dart` | Pass / Fail verdict with per-declaration breakdown |
| 10 | 📄 Report | `evidence_report_screen.dart` | Export PDF/JSON/CSV with blockchain hash + photos |
| 11 | 📋 Intake | `establishment_intake_screen.dart` | Structured form + GPS auto-fill + photo capture |
| 12 | 📜 History | `inspection_history_screen.dart` | Searchable, filterable list of all past inspections |
| 13 | 📶 Sync | `offline_sync_hub_screen.dart` | Pending upload queue, manual sync, conflict resolve |

#### 🏢 Nodal Officer Screens (2)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 14 | 📋 Dashboard | `nodal_dashboard_screen.dart` | District metrics, pending verifications, compliance trends |
| 15 | ✅ Verifier | `nodal_verifier_screen.dart` | Review inspector evidence — Approve / Reject / Return |

#### 🏛️ Commissioner Screens (2)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 16 | 📊 Dashboard | `commissioner_dashboard_screen.dart` | State-wide analytics, district comparison, heatmap |
| 17 | 🏛️ Portal | `commissioner_portal_screen.dart` | Legal notice generation, audit trail, policy management |

#### 👤 Citizen Screens (1)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 18 | 👤 Dashboard | `citizen_dashboard_screen.dart` | Verify products, file complaints, track complaint status |

---

## 🏗️ Architecture

```
lib/
│
├── main.dart                        App entry point, MaterialApp, named routes
│
├── core/                            Foundation Layer
│   ├── theme.dart                   Material 3 design system (colors, type, radii)
│   ├── api_client.dart              HTTP client — JWT auto-inject, error handling
│   ├── constants.dart               API base URL, endpoint paths, app constants
│   ├── role_guard.dart              RBAC gatekeeper — blocks unauthorized screens
│   └── storage_service.dart         Secure local storage (encrypted SharedPrefs)
│
├── models/
│   └── models.dart                  All Dart models: User, Inspection, Evidence, Product
│
├── providers/                       State Management (Provider pattern)
│   ├── auth_provider.dart           JWT tokens, login/logout, biometric, session
│   ├── scan_provider.dart           Camera capture, file pick, upload, AR data
│   ├── compliance_provider.dart     AI analysis, rule results, evidence hash
│   └── sync_provider.dart           Offline queue, sync progress, conflicts
│
├── screens/                         18 screens (see table above)
│
└── widgets/                         6 Reusable Components
    ├── parakh_logo.dart              Animated SVG brand logo
    ├── ar_overlay_box.dart           AR bounding box (green = ok, red = violation)
    ├── action_tile.dart              Dashboard quick-action cards
    ├── metric_card.dart              Dashboard metric display (value + label)
    ├── status_pill.dart              Status badge: Compliant / Violation / Pending
    └── custom_button.dart            Themed action button
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| Flutter SDK | 3.0+ | Run `flutter doctor` first |
| Dart | 3.0+ | Bundled with Flutter |
| Android SDK | API 21+ | Minimum SDK |
| Xcode | 14+ | macOS only, for iOS builds |
| Physical device | — | Strongly recommended for camera + GPS |

### Installation

```bash
# 1. Go to frontend directory
cd frontend

# 2. Get dependencies
flutter pub get

# 3. Launch on device or emulator
flutter run
```

### Connect to Backend

Edit `lib/core/constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_IP:8000/api/v1';
// Android emulator: http://10.0.2.2:8000/api/v1
// Physical device: use your machine's LAN IP
```

> See [`../tools/DEVICE_CONNECTIVITY_GUIDE.md`](../tools/DEVICE_CONNECTIVITY_GUIDE.md) for ADB setup.

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_svg` | ^2.0.10+1 | SVG logo rendering |
| `google_fonts` | ^6.2.1 | Inter typography |
| `provider` | ^6.1.2 | State management |
| `http` | ^1.2.1 | REST API calls |
| `intl` | ^0.19.0 | Date / number formatting |
| `shared_preferences` | ^2.2.3 | Local key-value storage |
| `crypto` | ^3.0.3 | SHA-256 client-side hashing |
| `uuid` | ^4.4.0 | Unique ID generation |
| `path_provider` | ^2.1.3 | App directory paths |
| `file_picker` | ^8.0.3 | Gallery image selection |
| `camera` | ^0.12.0+2 | Live camera for AR scanning |
| `geolocator` | ^13.0.1 | GPS for evidence tagging |
| `local_auth` | ^2.3.0 | Fingerprint / Face ID |
| `video_player` | ^2.9.2 | Splash screen video |

---

## 🎨 Design System

Defined in `lib/core/theme.dart` — Material 3-inspired:

### Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#1565C0` | Buttons, links, active states |
| `primaryContainer` | `#BBDEFB` | Selected states, chips |
| `surface` | `#FAFAFA` | Screen backgrounds |
| `error` | `#D32F2F` | Violation indicators, alerts |
| `onSurface` | `#212121` | Primary text |
| `textMuted` | `#757575` | Secondary / caption text |

### Typography
| Style | Font | Weight | Size |
|-------|------|--------|------|
| Headline | Inter (Google Fonts) | Bold 700 | 24sp |
| Title | Inter (Google Fonts) | SemiBold 600 | 18sp |
| Body | Inter (Google Fonts) | Regular 400 | 14sp |
| Caption | Inter (Google Fonts) | Medium 500 | 12sp |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `radiusSmall` | 8px | Input fields |
| `radiusMedium` | 12px | Cards |
| `radiusLarge` | 16px | Bottom sheets |
| `radiusPill` | 24px | Status badges |

---

## 🔒 Security Features

| Feature | Implementation |
|---------|---------------|
| 🔐 Biometric Lock | Fingerprint / Face ID via `local_auth` |
| 🔑 Secure Token Storage | JWT encrypted in `SharedPreferences` |
| 📍 GPS Evidence Tagging | All scans tagged with precise coordinates |
| #️⃣ Client-Side Hashing | SHA-256 via `crypto` package before upload |
| 🛡️ RBAC Guard | `RoleGuard.enforceAccess()` gates every screen |

---

## 🔑 Permissions

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### iOS (`Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>PARAKH needs camera access to scan product labels.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>PARAKH needs location to tag inspection evidence with GPS coordinates.</string>
<key>NSFaceIDUsageDescription</key>
<string>PARAKH uses Face ID for secure biometric login.</string>
```

---

## 🏗️ Build & Release

### Android APK

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)

```bash
flutter build ios --release
# Archive via Xcode for App Store submission
```

### App Icon

```bash
flutter pub run flutter_launcher_icons
```

---

## 🧪 Testing

```bash
flutter test
flutter test --coverage
```

---

> **📱 PARAKH Mobile** — *Field enforcement at your fingertips*
>
> Part of [Project PARAKH](../README.md) — Government of India
