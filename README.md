<![CDATA[# 🏛️ Project PARAKH

### **Product Analysis & Regulatory Assessment for Known Hazards**

> An AI-powered Legal Metrology enforcement platform built for the **Ministry of Consumer Affairs, Food & Public Distribution (DoCA), Government of India**.
>
> **Problem Statement ID:** 26034 | **Smart India Hackathon**

---

## Table of Contents

- [What is PARAKH?](#-what-is-parakh)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [AI / Computer Vision Pipeline](#-ai--computer-vision-pipeline)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Mobile App — Screens & Navigation](#-mobile-app--screens--navigation)
- [Quick Start Guide](#-quick-start-guide)
- [Environment Variables Reference](#-environment-variables-reference)
- [API Endpoints](#-api-endpoints)
- [Security Architecture](#-security-architecture)
- [Roles & Permissions (RBAC)](#-roles--permissions-rbac)
- [Legal & Regulatory Framework](#-legal--regulatory-framework)
- [Deployment Guide](#-deployment-guide)
- [Documentation Index](#-documentation-index)
- [License](#-license)

---

## 🎯 What is PARAKH?

PARAKH automates product label compliance verification for enforcement officers under the **Legal Metrology Act, 2009** and the **Packaged Commodities Rules, 2011**.

A field inspector scans product packaging using a mobile device. The system then:

1. **Captures** — high-resolution images of product labels via AR-guided camera.
2. **Extracts** — text from packaging using Google Cloud Vision OCR.
3. **Understands** — named-entity recognition (BERT NER) identifies manufacturer, net quantity, MRP, address, customer-care, and more.
4. **Validates** — a rule engine cross-checks extracted declarations against all 14 mandatory fields defined in Schedule I/II of the Packaged Commodities Rules.
5. **Detects Anomalies** — a Vision Transformer (ViT) flags tampered labels, overprinted MRPs, and missing declarations.
6. **Predicts Risk** — a gradient-boosted classifier scores products on their likelihood of non-compliance.
7. **Commits Evidence** — SHA-256 hash of (Image + GPS + Timestamp + OCR + Violations) is committed to a Hyperledger Fabric blockchain for tamper-proof legal admissibility.
8. **Reports** — generates digital compliance reports in **PDF, JSON, and CSV** formats with cryptographic verification.

---

## ✨ Key Features

### For Inspectors
- 📸 **AR-Guided Camera** — real-time label detection with overlay boxes for guided capture
- 🔍 **Barcode Scanner** — GS1 Modulo-10 checksum validation with live Open Food Facts registry lookup
- 🤖 **AI Compliance Check** — one-tap full pipeline: OCR → NER → Rule Engine → Anomaly Detection
- 📋 **Establishment Intake** — structured form for capturing establishment details, GPS coordinates, and photos
- 📄 **Report Generation** — multi-format export (PDF with digital signature, JSON, CSV)
- 🔗 **Blockchain Evidence** — SHA-256 evidence hash committed to Hyperledger Fabric
- 📶 **Offline Mode** — full functionality with local database; auto-sync when connectivity resumes
- 📊 **Inspection History** — searchable repository of all scanned products and past inspections

### For Nodal Officers
- 🗺️ **Violation Heatmaps** — geographic cluster visualization of non-compliance hotspots
- ✅ **Verification Queue** — review, approve, or return inspector-submitted evidence
- 📈 **Analytics Dashboard** — real-time metrics on inspection volume, compliance rates, and pending cases

### For Commissioners
- 🏢 **State-Wide Analytics** — aggregated statistics across all districts and nodal offices
- 📜 **Legal Notice Generation** — automated PDF legal notices with pre-filled violation details
- 🔍 **Audit Trail** — complete system audit log with timestamp, actor, and action details

### For Citizens
- 📱 **Consumer Portal** — scan barcodes to verify product authenticity
- 📝 **Complaint Filing** — submit complaints with photo evidence
- 💬 **WhatsApp Integration** — report violations via WhatsApp Business API

---

## 🧩 System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      MOBILE / EDGE CLIENT                          │
│           Flutter 3.x + ARCore/ARKit + Camera + GPS                │
│     (18 Screens: Splash, Login, 4 Role Dashboards, AR Scan,       │
│      Barcode, AI Review, Compliance Verdict, Evidence Report,      │
│      Intake, Nodal Verifier, Commissioner Portal, History,         │
│      Offline Sync, Profile Settings)                               │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ REST API (HTTPS / JWT)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       BACKEND (FastAPI + Uvicorn)                   │
│                                                                     │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │
│  │ Auth & RBAC   │  │ API Gateway  │  │ Rate Limiter (SlowAPI)   │ │
│  │ (JWT+Argon2)  │  │ (15 Routers) │  │ Per-endpoint throttling  │ │
│  └───────────────┘  └──────┬───────┘  └──────────────────────────┘ │
│                             │                                       │
│  ┌──────────────────────────▼──────────────────────────────────┐   │
│  │               AI / COMPUTER VISION PIPELINE                 │   │
│  │                                                             │   │
│  │  ┌──────────┐  ┌───────────┐  ┌───────────┐  ┌──────────┐  │   │
│  │  │ OpenCV   │→ │ Cloud     │→ │ BERT NER  │→ │ Rule     │  │   │
│  │  │ (CLAHE,  │  │ Vision    │  │ (Entity   │  │ Engine   │  │   │
│  │  │ Contour) │  │ OCR       │  │ Extract)  │  │ (14 Dcl) │  │   │
│  │  └──────────┘  └───────────┘  └───────────┘  └──────────┘  │   │
│  │                                                             │   │
│  │  ┌──────────┐  ┌───────────┐  ┌───────────────────────────┐ │   │
│  │  │ ViT      │  │ Gradient  │  │ SHA-256 Evidence Hash    │ │   │
│  │  │ Anomaly  │  │ Boosting  │  │ → Blockchain Commit      │ │   │
│  │  │ Detector │  │ Predictor │  │                           │ │   │
│  │  └──────────┘  └───────────┘  └───────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌──────────────────┐ ┌────────────────┐ ┌──────────────────────┐  │
│  │   PostgreSQL 15+ │ │   MongoDB 6+   │ │  MinIO / Local FS    │  │
│  │   (Relational +  │ │   (AI Logs,    │ │  (Image Storage,     │  │
│  │    Cache + Queue) │ │    Raw OCR)    │ │   Evidence Files)    │  │
│  └──────────────────┘ └────────────────┘ └──────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │          Hyperledger Fabric (NIC MeghRaj Cloud)              │   │
│  │      Tamper-proof evidence ledger for legal admissibility    │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🧠 AI / Computer Vision Pipeline

The backend processes each product image through a **six-stage pipeline**:

| Stage | Module | Technology | Purpose |
|-------|--------|-----------|---------|
| 1. **Pre-Processing** | `ai/image_processor.py` | OpenCV 4.x | CLAHE contrast enhancement, 3D unwarping, contour detection, rotation correction |
| 2. **OCR** | `ai/ocr_engine.py` | Google Cloud Vision API | Full-text extraction with word-level bounding boxes and confidence scores |
| 3. **NER** | `ai/nlp_extractor.py` | HuggingFace `dslim/bert-base-NER` | Named-entity recognition to classify manufacturer, address, quantity, MRP, dates, etc. |
| 4. **Compliance** | `rules/compliance_engine.py` | Custom Rule Engine | Validates all 14 mandatory declarations under Packaged Commodities Rules 2011 |
| 5. **Anomaly Detection** | `ai/anomaly_detector.py` | HuggingFace `google/vit-base-patch16-224` | Vision Transformer for detecting tampered labels, overprinted MRPs, missing fields |
| 6. **Risk Prediction** | `ai/predictive.py` | scikit-learn `GradientBoostingClassifier` | Scores products on non-compliance probability based on historical patterns |

Additionally:
- **AI Triage** (`ai/ai_triage.py`) — prioritizes inspection queue based on risk scores
- **Evidence Hashing** — SHA-256 digest of (image bytes + GPS + timestamp + OCR text + violation list) for blockchain commit

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Mobile/Edge** | Flutter 3.x + ARCore/ARKit | Cross-platform mobile with AR overlay |
| **State Management** | Provider Pattern | Reactive state management |
| **Backend** | Python 3.11+ / FastAPI / Uvicorn | Async REST API server |
| **OCR** | Google Cloud Vision API | Cloud-native text extraction |
| **NLP** | HuggingFace Transformers (`dslim/bert-base-NER`) | Named-entity recognition |
| **Computer Vision** | OpenCV 4.x | Image pre-processing & enhancement |
| **Anomaly Detection** | HuggingFace ViT (`google/vit-base-patch16-224`) | Visual anomaly detection |
| **Predictive Analytics** | scikit-learn (`GradientBoostingClassifier`) | Risk scoring |
| **Relational DB** | PostgreSQL 15+ (asyncpg) | Primary data store |
| **Cache & Task Queue** | PostgreSQL-native | Zero-dependency caching (no Redis) |
| **NoSQL / AI Logs** | MongoDB 6+ (Motor async driver) | Raw OCR dumps & AI audit logs |
| **Object Storage** | MinIO (S3-compatible) or Local FS | Image & evidence file storage |
| **Blockchain** | Hyperledger Fabric on NIC MeghRaj | Tamper-proof evidence ledger |
| **Integrations** | Open Food Facts API | Product registry verification |
| **Messaging** | WhatsApp Business API | Citizen complaint channel |
| **Auth** | JWT (HS256) + Argon2/BCrypt | Token-based authentication |
| **Rate Limiting** | SlowAPI | Per-endpoint request throttling |

---

## 📁 Project Structure

```
T1/
├── README.md                           # This file
├── .gitignore
├── analysis_options.yaml               # Dart lint rules
│
├── backend/                            # Python FastAPI Backend
│   ├── app/
│   │   ├── main.py                     # Application entry point (Uvicorn)
│   │   ├── config.py                   # Settings (Pydantic BaseSettings)
│   │   │
│   │   ├── ai/                         # AI / Computer Vision Pipeline
│   │   │   ├── image_processor.py      # OpenCV: CLAHE, unwarping, contours
│   │   │   ├── ocr_engine.py           # Google Cloud Vision OCR
│   │   │   ├── nlp_extractor.py        # BERT NER entity extraction
│   │   │   ├── anomaly_detector.py     # ViT anomaly detection
│   │   │   ├── predictive.py           # GradientBoosting risk scoring
│   │   │   └── ai_triage.py            # Inspection queue prioritization
│   │   │
│   │   ├── api/
│   │   │   ├── deps.py                 # Dependency injection (auth, DB sessions)
│   │   │   └── v1/                     # Versioned API routers
│   │   │       ├── router.py           # Master router (mounts all sub-routers)
│   │   │       ├── auth.py             # Login, register, token refresh
│   │   │       ├── users.py            # User profile CRUD
│   │   │       ├── scan.py             # Image upload & barcode lookup
│   │   │       ├── analysis.py         # Full AI compliance pipeline
│   │   │       ├── inspections.py      # Inspection CRUD + report export
│   │   │       ├── compliance.py       # Rule engine results
│   │   │       ├── evidence.py         # Blockchain evidence commit/verify
│   │   │       ├── citizen.py          # Citizen complaints & WhatsApp
│   │   │       ├── analytics.py        # Dashboard statistics
│   │   │       ├── heatmaps.py         # Geographic violation clusters
│   │   │       ├── legal_notices.py    # PDF legal notice generation
│   │   │       ├── audit.py            # System audit trail
│   │   │       ├── sync.py             # Offline data synchronization
│   │   │       └── health.py           # Liveness & readiness probes
│   │   │
│   │   ├── analytics/                  # Analytics aggregation logic
│   │   ├── audit/                      # Audit trail service
│   │   ├── blockchain/                 # Hyperledger Fabric client
│   │   ├── core/                       # Security, RBAC, rate limiter, PG cache & queue
│   │   ├── db/                         # PostgreSQL & MongoDB connectors
│   │   ├── integrations/               # Open Food Facts, WhatsApp Business API
│   │   ├── models/                     # SQLAlchemy ORM models
│   │   ├── repositories/              # Data access layer (repository pattern)
│   │   ├── rules/                      # Legal Metrology compliance rule engine
│   │   ├── schemas/                    # Pydantic request/response schemas
│   │   ├── security/                   # Password hashing, JWT, encryption
│   │   ├── services/                   # Business logic layer
│   │   └── storage/                    # MinIO & local file storage adapters
│   │
│   ├── tests/                          # pytest unit & integration tests
│   ├── requirements.txt
│   └── .env.example                    # Environment variables template
│
├── frontend/                           # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                   # App entry point & route definitions
│   │   │
│   │   ├── core/                       # Foundation Layer
│   │   │   ├── theme.dart              # Material 3 design system, colors, typography
│   │   │   ├── api_client.dart         # HTTP client with JWT interceptor
│   │   │   ├── constants.dart          # API URLs, endpoints, app constants
│   │   │   ├── role_guard.dart         # RBAC UI gatekeeper (role-based routing)
│   │   │   └── storage_service.dart    # Flutter Secure Storage wrapper
│   │   │
│   │   ├── models/                     # Dart data models (User, Product, Inspection, etc.)
│   │   ├── providers/                  # State management (Provider pattern)
│   │   │
│   │   ├── screens/                    # 18 Application Screens
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── dashboard_screen.dart           # Role router (redirects by role)
│   │   │   ├── inspector_dashboard_screen.dart
│   │   │   ├── nodal_dashboard_screen.dart
│   │   │   ├── commissioner_dashboard_screen.dart
│   │   │   ├── citizen_dashboard_screen.dart
│   │   │   ├── ar_camera_screen.dart
│   │   │   ├── barcode_scanner_screen.dart
│   │   │   ├── ai_review_screen.dart
│   │   │   ├── compliance_verdict_screen.dart
│   │   │   ├── evidence_report_screen.dart
│   │   │   ├── establishment_intake_screen.dart
│   │   │   ├── nodal_verifier_screen.dart
│   │   │   ├── commissioner_portal_screen.dart
│   │   │   ├── inspection_history_screen.dart
│   │   │   ├── offline_sync_hub_screen.dart
│   │   │   └── profile_settings_screen.dart
│   │   │
│   │   └── widgets/                    # 6 Reusable UI Components
│   │       ├── action_tile.dart        # Tappable action card
│   │       ├── ar_overlay_box.dart     # AR bounding box overlay
│   │       ├── custom_button.dart      # Themed button component
│   │       ├── metric_card.dart        # Dashboard metric card
│   │       ├── parakh_logo.dart        # Animated logo widget
│   │       └── status_pill.dart        # Status badge (Compliant/Violation/Pending)
│   │
│   ├── assets/                         # Logo SVG/PNG, splash video
│   ├── android/                        # Android platform configuration
│   ├── ios/                            # iOS platform configuration
│   └── pubspec.yaml                    # Flutter dependencies
│
└── tools/                              # Documentation, Scripts & Resources
    ├── LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md
    ├── USER_TYPES_AND_ROLES.md
    ├── INSTRUCTIONS.md
    ├── DEVICE_CONNECTIVITY_GUIDE.md
    ├── Advanced_Legal_Metrology_Features.md
    ├── Project_PARAKH_AI_Architecture.md
    ├── Project_PARAKH_AI_Models.md
    ├── Project_PARAKH_API_Gateway.md
    ├── Project_PARAKH_Architecture.md
    ├── Project_PARAKH_Documentation.md
    ├── Project_PARAKH_Legal_Metrology_Rules.md
    ├── Project_PARAKH_Mobile_App_Pages.md
    ├── Project_PARAKH_PRD.md
    ├── Project_PARAKH_Security_Layer.md
    ├── Project_PARAKH_TechStack.md
    ├── legal_metrology_rules_2011.json   # Machine-readable rules database
    ├── connect_device.bat                # Windows device connection script
    ├── connect_device.ps1                # PowerShell device connection script
    └── splash_video.mp4                  # Splash screen animation
```

---

## 📱 Mobile App — Screens & Navigation

The Flutter application contains **18 screens** organized by user role:

### Common Screens
| Screen | File | Description |
|--------|------|-------------|
| Splash | `splash_screen.dart` | Animated logo + video splash with auto-navigation |
| Login | `login_screen.dart` | Biometric + credential authentication with role selection |
| Profile | `profile_settings_screen.dart` | User profile, preferences, and logout |

### Inspector Screens
| Screen | File | Description |
|--------|------|-------------|
| Inspector Dashboard | `inspector_dashboard_screen.dart` | Metrics (inspections today, violations, pending sync), quick-action tiles |
| AR Camera | `ar_camera_screen.dart` | ARCore/ARKit guided camera with real-time label bounding boxes |
| Barcode Scanner | `barcode_scanner_screen.dart` | GS1 barcode scan + Open Food Facts verification + manual GTIN entry |
| AI Review | `ai_review_screen.dart` | Side-by-side: original image ↔ AI extracted fields with confidence scores |
| Compliance Verdict | `compliance_verdict_screen.dart` | Pass/Fail verdict with per-declaration breakdown |
| Evidence Report | `evidence_report_screen.dart` | Generate PDF/JSON/CSV report with blockchain hash, photo attachments |
| Establishment Intake | `establishment_intake_screen.dart` | Structured establishment data form + GPS auto-fill |
| Inspection History | `inspection_history_screen.dart` | Searchable, filterable list of past inspections |
| Offline Sync Hub | `offline_sync_hub_screen.dart` | View pending uploads, trigger manual sync, resolve conflicts |

### Nodal Officer Screens
| Screen | File | Description |
|--------|------|-------------|
| Nodal Dashboard | `nodal_dashboard_screen.dart` | District-level metrics, pending verifications, compliance trends |
| Nodal Verifier | `nodal_verifier_screen.dart` | Review inspector evidence, approve/reject/return with comments |

### Commissioner Screens
| Screen | File | Description |
|--------|------|-------------|
| Commissioner Dashboard | `commissioner_dashboard_screen.dart` | State-wide analytics, district comparison, violation heatmap |
| Commissioner Portal | `commissioner_portal_screen.dart` | Legal notice generation, audit trail, policy management |

### Citizen Screens
| Screen | File | Description |
|--------|------|-------------|
| Citizen Dashboard | `citizen_dashboard_screen.dart` | Barcode verification, file complaints, track complaint status |

### Navigation Flow
```
Splash → Login → Role Router
                    ├── Inspector → Dashboard → AR Camera → AI Review → Verdict → Report
                    ├── Nodal     → Dashboard → Verifier Queue
                    ├── Commissioner → Dashboard → Portal → Legal Notices
                    └── Citizen   → Dashboard → Barcode Verify → File Complaint
```

---

## 🚀 Quick Start Guide

### Prerequisites

| Requirement | Version | Purpose |
|---|---|---|
| Python | 3.11+ | Backend runtime |
| Flutter SDK | 3.x | Mobile application |
| PostgreSQL | 15+ | Primary database |
| MongoDB | 6+ | AI logs & raw OCR storage |
| MinIO | Latest | Object storage (optional, can use local FS) |
| Google Cloud Vision API Key | — | Live OCR (optional for demo mode) |
| Android Studio / Xcode | Latest | Mobile emulator/device |

### 1. Clone the Repository

```bash
git clone https://github.com/jitendrachoudhary1401-hue/Parakh.git
cd Parakh/models/T1
```

### 2. Backend Setup

```bash
cd backend

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate          # Linux/macOS
# venv\Scripts\activate           # Windows

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your actual credentials (see Environment Variables section)

# Start the server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://localhost:8000`. Interactive documentation at `http://localhost:8000/docs`.

### 3. Mobile App Setup

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Connect a device or start an emulator
# (See tools/DEVICE_CONNECTIVITY_GUIDE.md for detailed instructions)

# Launch the app
flutter run
```

### 4. Connect Mobile to Backend

Update `frontend/lib/core/constants.dart` with your backend IP:

```dart
static const String apiBaseUrl = 'http://<YOUR_IP>:8000/api/v1';
```

For Android emulator use `10.0.2.2` as the IP address.

---

## ⚙️ Environment Variables Reference

Copy `backend/.env.example` to `backend/.env` and configure:

### Core Settings
| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | Environment: `development`, `staging`, `production` |
| `DEBUG` | `true` | Debug mode toggle |
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `8000` | Server port |
| `WORKERS` | `4` | Uvicorn worker count |

### Database
| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | — | PostgreSQL async connection string (asyncpg) |
| `DATABASE_URL_SYNC` | — | PostgreSQL sync connection for Alembic migrations |
| `DB_POOL_SIZE` | `20` | Connection pool size |
| `MONGODB_URL` | `mongodb://localhost:27017` | MongoDB connection string |
| `MONGODB_DATABASE` | `parakh_db` | MongoDB database name |

### Authentication & Security
| Variable | Default | Description |
|---|---|---|
| `JWT_SECRET_KEY` | — | **MUST CHANGE.** JWT signing secret |
| `JWT_ALGORITHM` | `HS256` | JWT algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access token TTL |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | `7` | Refresh token TTL |
| `ENCRYPTION_KEY` | — | **MUST CHANGE.** AES-256 encryption key (32-byte base64) |

### AI / ML
| Variable | Default | Description |
|---|---|---|
| `NER_MODEL_NAME` | `dslim/bert-base-NER` | HuggingFace NER model |
| `VIT_MODEL_NAME` | `google/vit-base-patch16-224` | HuggingFace ViT model |
| `NER_CONFIDENCE_THRESHOLD` | `0.5` | Minimum NER confidence |
| `ANOMALY_DETECTION_ENABLED` | `true` | Enable/disable ViT anomaly detection |

### External Services
| Variable | Default | Description |
|---|---|---|
| `GOOGLE_CLOUD_VISION_KEY` | — | Google Cloud Vision API key |
| `OPENFOODFACTS_API_URL` | `https://world.openfoodfacts.org/api/v2` | Product registry API |
| `WHATSAPP_ENABLED` | `false` | Enable WhatsApp Business integration |
| `BLOCKCHAIN_ENABLED` | `false` | Enable Hyperledger Fabric integration |

### Storage
| Variable | Default | Description |
|---|---|---|
| `STORAGE_PROVIDER` | `minio` | Storage backend: `minio` or `local` |
| `MINIO_ENDPOINT_URL` | `http://localhost:9000` | MinIO server URL |
| `LOCAL_STORAGE_PATH` | — | Local filesystem path (when `STORAGE_PROVIDER=local`) |

### Rate Limiting
| Variable | Default | Description |
|---|---|---|
| `RATE_LIMIT_LOGIN` | `5/minute` | Login endpoint throttle |
| `RATE_LIMIT_UPLOAD` | `20/minute` | Image upload throttle |
| `RATE_LIMIT_ANALYSIS` | `10/minute` | AI analysis throttle |
| `RATE_LIMIT_DEFAULT` | `60/minute` | Default endpoint throttle |

---

## 📊 API Endpoints

All endpoints are prefixed with `/api/v1`. Interactive documentation available at `/docs` (Swagger UI).

### Health & System
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | — | Liveness probe |
| `GET` | `/ready` | — | Readiness probe (DB connectivity check) |

### Authentication
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/auth/login` | — | JWT login (returns access + refresh tokens) |
| `POST` | `/auth/register` | — | User registration |

### User Management
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/users/me` | JWT | Current user profile |
| `PUT` | `/users/{id}` | JWT | Update user profile |

### Scanning & Processing
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/scan/upload` | JWT | Upload product image |
| `POST` | `/scan/process` | JWT | Trigger AI pipeline on uploaded image |
| `GET` | `/scan/barcode/{gtin}` | — | Public barcode lookup (rate-limited) |

### Analysis & Compliance
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/analysis/{id}/verify` | JWT | Run full compliance pipeline |
| `GET` | `/compliance/{id}` | JWT | Get rule engine results |

### Inspections
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/inspections` | JWT | List inspections (paginated, filterable) |
| `POST` | `/inspections` | JWT | Create new inspection record |
| `GET` | `/inspections/{id}/export/pdf` | JWT | Export inspection as PDF report |
| `GET` | `/inspections/{id}/export/json` | JWT | Export inspection as JSON |
| `GET` | `/inspections/{id}/export/csv` | JWT | Export inspection as CSV |

### Evidence & Blockchain
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/evidence/commit` | JWT | Commit evidence hash to blockchain |
| `GET` | `/evidence/verify` | JWT | Verify evidence integrity |

### Citizen Portal
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/citizen/report` | JWT | Submit citizen complaint |
| `POST` | `/citizen/whatsapp` | — | WhatsApp webhook (inbound messages) |

### Analytics & Reporting
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/analytics/summary` | JWT | Dashboard analytics (role-filtered) |
| `GET` | `/heatmaps` | JWT | Geographic violation clusters |
| `POST` | `/legal-notices/generate` | JWT | Generate PDF legal notice |
| `GET` | `/audit/logs` | JWT (Admin) | System audit trail |

### Offline Sync
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/sync/push` | JWT | Push offline records to server |
| `GET` | `/sync/pull` | JWT | Pull latest records to device |

---

## 🔐 Security Architecture

### Authentication
- **OAuth2-compliant JWT** (HS256) with configurable access/refresh token TTLs
- **Password hashing**: Argon2 (primary) with BCrypt fallback
- **Biometric authentication** on mobile (fingerprint/face)

### Authorization (RBAC)
- **Frontend**: `RoleGuard` widget gates UI routes — users can only see screens matching their role
- **Backend**: `deps.py` dependency injection enforces role checks on every protected endpoint
- **4 roles**: Inspector, Nodal Officer, Commissioner, Citizen

### Data Protection
- **AES-256 encryption** for sensitive data at rest
- **SHA-256 evidence hashing** with blockchain commit
- **MIME-type + magic-byte validation** on all file uploads
- **Max upload size**: 25 MB

### Rate Limiting
- Per-endpoint SlowAPI rate limiting (login: 5/min, upload: 20/min, analysis: 10/min)
- Configurable via environment variables

### Evidence Integrity
- SHA-256 hash computed over: `image_bytes + GPS_coordinates + timestamp + OCR_text + violations_json`
- Hash committed to **Hyperledger Fabric** for tamper-proof legal admissibility under **Section 65B, Indian Evidence Act**

---

## 👥 Roles & Permissions (RBAC)

| Feature | Inspector | Nodal Officer | Commissioner | Citizen |
|---|:---:|:---:|:---:|:---:|
| Scan Products (Camera/AR) | ✅ | ❌ | ❌ | ❌ |
| Barcode Lookup | ✅ | ✅ | ✅ | ✅ |
| AI Compliance Check | ✅ | ❌ | ❌ | ❌ |
| Submit Evidence | ✅ | ❌ | ❌ | ❌ |
| Establishment Intake | ✅ | ❌ | ❌ | ❌ |
| Generate Reports | ✅ | ✅ | ✅ | ❌ |
| View Inspection History | ✅ | ✅ | ✅ | ❌ |
| Verify/Approve Evidence | ❌ | ✅ | ✅ | ❌ |
| District Analytics | ❌ | ✅ | ✅ | ❌ |
| State-Wide Analytics | ❌ | ❌ | ✅ | ❌ |
| Generate Legal Notices | ❌ | ❌ | ✅ | ❌ |
| View Audit Trail | ❌ | ❌ | ✅ | ❌ |
| File Complaints | ❌ | ❌ | ❌ | ✅ |
| Track Complaints | ❌ | ❌ | ❌ | ✅ |
| WhatsApp Reporting | ❌ | ❌ | ❌ | ✅ |
| Offline Sync | ✅ | ❌ | ❌ | ❌ |

> For the complete RBAC matrix including backend enforcement details, see [`tools/USER_TYPES_AND_ROLES.md`](tools/USER_TYPES_AND_ROLES.md).

---

## 📜 Legal & Regulatory Framework

This system enforces compliance with:

| Legislation | Relevance |
|---|---|
| **Legal Metrology Act, 2009** | Primary governing statute for weights & measures enforcement |
| **Packaged Commodities Rules, 2011** (Amendment 2017) | 14 mandatory declarations on pre-packaged goods |
| **Section 65B, Indian Evidence Act** | Electronic evidence admissibility in court |
| **IT Act, 2000** | Digital signature and data protection requirements |
| **Consumer Protection Act, 2019** | Citizen complaint handling and redressal framework |
| **BIS Standards (IS 15778, IS 14543)** | Unit of measurement standards and date format requirements |

> For the full compliance checklist with Schedule I/II tables, see [`tools/LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md`](tools/LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md).

---

## 🚢 Deployment Guide

### Development (Local)

```bash
# Terminal 1: Backend
cd backend && uvicorn app.main:app --reload --port 8000

# Terminal 2: Mobile App
cd frontend && flutter run
```

### Staging / Production

#### Docker (Recommended)

```bash
# Backend
docker build -t parakh-backend ./backend
docker run -d \
  --name parakh-api \
  -p 8000:8000 \
  --env-file backend/.env \
  parakh-backend

# MinIO (Object Storage)
docker run -d \
  --name parakh-minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
```

#### Production Checklist

- [ ] Set `APP_ENV=production` and `DEBUG=false`
- [ ] Generate a strong `JWT_SECRET_KEY` and `ENCRYPTION_KEY`
- [ ] Configure PostgreSQL with SSL and connection pooling (PgBouncer)
- [ ] Enable `BLOCKCHAIN_ENABLED=true` with NIC MeghRaj credentials
- [ ] Configure MinIO with replication for data durability
- [ ] Set up HTTPS reverse proxy (Nginx / Traefik)
- [ ] Enable `AUDIT_LOG_ENABLED=true`
- [ ] Configure rate limits appropriate for expected load
- [ ] Build Flutter release APK: `flutter build apk --release`

### NIC MeghRaj Deployment (Government Cloud)

For deployment on Government of India infrastructure:
1. Provision VM on NIC MeghRaj portal
2. Install PostgreSQL 15+ and MongoDB 6+ on separate instances
3. Deploy backend behind NIC's load balancer
4. Connect to NIC's Hyperledger Fabric network for evidence chain
5. Submit APK to Government App Store for distribution

---

## 📄 Documentation Index

Detailed documentation is available in the `tools/` directory:

### Regulatory & Compliance
| Document | Description |
|---|---|
| [Compliance Checklist](tools/LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md) | Legal Metrology Rules 2011 compliance checklist with Schedule I/II tables |
| [User Types & Roles](tools/USER_TYPES_AND_ROLES.md) | Complete RBAC matrix, user roles, permissions & segregation of duties |
| [Legal Metrology Rules](tools/Project_PARAKH_Legal_Metrology_Rules.md) | Detailed rule definitions and penalty framework |
| [Advanced Features](tools/Advanced_Legal_Metrology_Features.md) | Extended compliance features and edge-case handling |

### Technical Architecture
| Document | Description |
|---|---|
| [AI Architecture](tools/Project_PARAKH_AI_Architecture.md) | Complete AI/ML pipeline design and model selection rationale |
| [AI Models](tools/Project_PARAKH_AI_Models.md) | Model specifications, training data, and performance benchmarks |
| [System Architecture](tools/Project_PARAKH_Architecture.md) | Backend architecture, data flow, and component interactions |
| [API Gateway](tools/Project_PARAKH_API_Gateway.md) | API gateway configuration and routing logic |
| [Security Layer](tools/Project_PARAKH_Security_Layer.md) | Security architecture, threat model, and mitigation strategies |
| [Tech Stack](tools/Project_PARAKH_TechStack.md) | Technology decisions, trade-offs, and rationale |

### Product & Integration
| Document | Description |
|---|---|
| [PRD](tools/Project_PARAKH_PRD.md) | Product Requirements Document |
| [API Documentation](tools/Project_PARAKH_Documentation.md) | API reference and integration guide |
| [Mobile App Pages](tools/Project_PARAKH_Mobile_App_Pages.md) | Mobile screen inventory and navigation map |
| [Device Connectivity](tools/DEVICE_CONNECTIVITY_GUIDE.md) | Guide for connecting Android/iOS devices for development |
| [Setup Instructions](tools/INSTRUCTIONS.md) | Detailed setup and configuration instructions |

### Data & Scripts
| File | Description |
|---|---|
| `legal_metrology_rules_2011.json` | Machine-readable rules database (14 mandatory declarations) |
| `connect_device.ps1` / `.bat` | Device connection automation scripts (Windows) |
| `splash_video.mp4` | Mobile app splash screen animation |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please ensure all contributions:
- Follow the existing code style and directory structure
- Include appropriate error handling
- Respect the RBAC boundaries defined in `role_guard.dart` and `deps.py`

---

## 📝 License

This project is developed for the **Government of India** under the Smart India Hackathon initiative. All rights reserved under applicable government licensing terms.

---

<p align="center">
  <strong>Project PARAKH</strong> — <em>Protecting Consumers. Empowering Enforcement. Powered by AI.</em>
  <br><br>
  Ministry of Consumer Affairs, Food & Public Distribution (DoCA) | Government of India
</p>
]]>
