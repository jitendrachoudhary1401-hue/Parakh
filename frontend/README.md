# 📱 Project PARAKH — Mobile App

### Flutter Mobile Application for Legal Metrology Field Enforcement

---

## 📋 Overview

The PARAKH mobile app is a **Flutter 3.x** application designed for field enforcement officers under the Legal Metrology Act, 2009. It provides AR-powered real-time product scanning, offline-first data synchronization, biometric authentication, and evidence capture with GPS tagging — all from a single handheld device.

---

## 🎨 App Screens

The application contains **11 fully implemented screens**:

| # | Screen | File | Description |
|---|---|---|---|
| 1 | **Splash** | `splash_screen.dart` | Video splash with auto-navigation to login/dashboard |
| 2 | **Login** | `login_screen.dart` | JWT authentication with biometric unlock option |
| 3 | **Dashboard** | `dashboard_screen.dart` | Officer dashboard with metrics, recent inspections, quick actions |
| 4 | **AR Camera** | `ar_camera_screen.dart` | Live camera with AR bounding box overlays and HUD controls |
| 5 | **Barcode Scanner** | `barcode_scanner_screen.dart` | Barcode scanning with Open Food Facts cross-reference |
| 6 | **AI Review** | `ai_review_screen.dart` | AI extraction results review (OCR text, entities, confidence) |
| 7 | **Compliance Verdict** | `compliance_verdict_screen.dart` | Rule-by-rule compliance pass/fail with evidence hash |
| 8 | **Evidence Report** | `evidence_report_screen.dart` | Blockchain evidence summary and verification status |
| 9 | **Offline Sync Hub** | `offline_sync_hub_screen.dart` | Pending sync queue, conflict resolution, sync status |
| 10 | **Inspection History** | `inspection_history_screen.dart` | Searchable history of all past inspections |
| 11 | **Profile Settings** | `profile_settings_screen.dart` | Officer profile, notification prefs, biometric toggle |

---

## 🏗️ Architecture

```
lib/
├── main.dart                   # App entry point, MaterialApp, route definitions
│
├── core/                       # Foundation Layer
│   ├── theme.dart              # AppTheme design system (colors, typography, radii)
│   ├── api_client.dart         # HTTP client with JWT token management
│   ├── constants.dart          # API base URLs, app constants
│   └── storage_service.dart    # Secure local storage (SharedPreferences + encrypted)
│
├── models/                     # Data Models
│   └── models.dart             # All Dart model classes (Inspection, User, Evidence, etc.)
│
├── providers/                  # State Management (Provider Pattern)
│   ├── auth_provider.dart      # Authentication state, JWT token, login/logout
│   ├── scan_provider.dart      # Camera scan state, image processing, AR data
│   ├── compliance_provider.dart # Compliance check state, rule results, evidence
│   └── sync_provider.dart      # Offline sync queue state, conflict tracking
│
├── screens/                    # 11 Application Screens (listed above)
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── ar_camera_screen.dart
│   ├── barcode_scanner_screen.dart
│   ├── ai_review_screen.dart
│   ├── compliance_verdict_screen.dart
│   ├── evidence_report_screen.dart
│   ├── offline_sync_hub_screen.dart
│   ├── inspection_history_screen.dart
│   └── profile_settings_screen.dart
│
└── widgets/                    # 6 Reusable UI Components
    ├── parakh_logo.dart        # PARAKH SVG brand logo widget
    ├── ar_overlay_box.dart     # AR bounding box overlay with compliance color coding
    ├── action_tile.dart        # Dashboard quick-action tiles
    ├── metric_card.dart        # Dashboard metric display cards
    ├── status_pill.dart        # Compliance status badge (Compliant/Violation/Pending)
    └── custom_button.dart      # Themed action button component
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | 3.0+ |
| Dart | 3.0+ |
| Android SDK | API 21+ (minSdk) |
| Xcode (macOS only) | 14+ for iOS builds |
| Physical device | Recommended for camera and GPS |

### Installation

```bash
# 1. Navigate to frontend directory
cd frontend

# 2. Install Flutter dependencies
flutter pub get

# 3. Run on connected device or emulator
flutter run

# 4. Build release APK
flutter build apk --release
```

### Backend Connection

Update the API base URL in `lib/core/constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_IP:8000/api/v1';
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_svg` | ^2.0.10+1 | SVG logo rendering |
| `google_fonts` | ^6.2.1 | Inter, Roboto typography |
| `provider` | ^6.1.2 | State management |
| `http` | ^1.2.1 | REST API communication |
| `intl` | ^0.19.0 | Date/number formatting |
| `shared_preferences` | ^2.2.3 | Local key-value storage |
| `crypto` | ^3.0.3 | SHA-256 client-side hashing |
| `uuid` | ^4.4.0 | Unique ID generation |
| `path_provider` | ^2.1.3 | App directory paths |
| `file_picker` | ^8.0.3 | Image file selection from gallery |
| `camera` | ^0.12.0+2 | Live camera access for AR scanning |
| `geolocator` | ^13.0.1 | GPS location for evidence tagging |
| `local_auth` | ^2.3.0 | Biometric (fingerprint/face) authentication |
| `video_player` | ^2.9.2 | Video splash screen playback |

---

## 🔑 Mandatory Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

| Permission | Purpose | When Requested |
|---|---|---|
| `CAMERA` | AR product scanning, image capture | On first scan launch |
| `ACCESS_FINE_LOCATION` | GPS coordinates for evidence tagging | On first scan launch |
| `ACCESS_COARSE_LOCATION` | Fallback GPS | On first scan launch |
| `USE_BIOMETRIC` | Fingerprint/face unlock | On login if enabled |
| `INTERNET` | Backend API communication | Automatic (manifest) |

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>PARAKH needs camera access to scan product labels.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>PARAKH needs location to tag inspection evidence with GPS coordinates.</string>
<key>NSFaceIDUsageDescription</key>
<string>PARAKH uses Face ID for secure biometric login.</string>
```

---

## 🎨 Design System

The app uses a custom Material 3-inspired design system defined in `lib/core/theme.dart`:

### Color Palette
| Token | Hex | Usage |
|---|---|---|
| `primary` | `#1565C0` | Buttons, links, active elements |
| `primaryContainer` | `#BBDEFB` | Selected states, chips |
| `surface` | `#FAFAFA` | Screen backgrounds |
| `surfaceContainerLow` | `#F5F5F5` | Cards, tiles |
| `error` | `#D32F2F` | Violation indicators |
| `onSurface` | `#212121` | Primary text |
| `textMuted` | `#757575` | Secondary text |

### Typography
| Style | Font | Weight | Size |
|---|---|---|---|
| Headline | Google Fonts (Inter) | Bold (700) | 24sp |
| Title | Google Fonts (Inter) | SemiBold (600) | 18sp |
| Body | Google Fonts (Inter) | Regular (400) | 14sp |
| Caption | Google Fonts (Inter) | Medium (500) | 12sp |

### Border Radius
| Token | Value | Usage |
|---|---|---|
| `radiusSmall` | 8px | Input fields |
| `radiusMedium` | 12px | Cards |
| `radiusLarge` | 16px | Bottom sheets |
| `radiusPill` | 24px | Badges, pills |

---

## 📱 Navigation Flow

```
App Launch
    │
    ▼
Splash Screen (Video)
    │
    ├── Authenticated ──► Dashboard
    │                       ├── AR Camera Scan ──► AI Review ──► Compliance Verdict ──► Evidence Report
    │                       ├── Barcode Scanner ──► AI Review ──► Compliance Verdict
    │                       ├── Inspection History
    │                       ├── Offline Sync Hub
    │                       └── Profile Settings
    │
    └── Not Authenticated ──► Login Screen ──► Dashboard
```

---

## 📡 State Management

The app uses the **Provider** pattern with 4 state providers:

| Provider | File | Responsibilities |
|---|---|---|
| `AuthProvider` | `auth_provider.dart` | JWT token management, login/logout, biometric unlock, session persistence |
| `ScanProvider` | `scan_provider.dart` | Camera image capture, file picking, image-to-backend upload, AR overlay data |
| `ComplianceProvider` | `compliance_provider.dart` | AI analysis trigger, rule results, evidence hash display, verdict tracking |
| `SyncProvider` | `sync_provider.dart` | Offline inspection queue, sync progress, conflict resolution |

---

## 🔌 API Client

The `ApiClient` (`lib/core/api_client.dart`) handles all backend communication:

* **Base URL**: Configurable via `Constants.baseUrl`
* **Authentication**: Automatic `Authorization: Bearer <token>` header injection
* **Error Handling**: Standardized error parsing and user-facing error messages
* **Offline Support**: Queues failed requests for retry when connectivity is restored

---

## 🏗️ Build & Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)
```bash
flutter build ios --release
# Then archive via Xcode
```

### App Icon Generation
```bash
flutter pub run flutter_launcher_icons
```

---

## 🧪 Testing

```bash
# Run widget tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 🔒 Security Features

* **Biometric Lock**: Optional fingerprint/Face ID authentication via `local_auth`
* **Secure Token Storage**: JWT stored in encrypted `SharedPreferences`
* **GPS Evidence**: All scans are tagged with precise GPS coordinates
* **Client-Side Hashing**: SHA-256 pre-computation using `crypto` package
* **Certificate Pinning**: Ready for production TLS certificate pinning
