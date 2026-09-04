# 🏛️ Project PARAKH
## Product Analysis & Regulatory Assessment for Known Hazards

> AI-powered Legal Metrology enforcement platform for the **Ministry of Consumer Affairs, Food & Public Distribution (DoCA), Government of India**
> 
> **Problem Statement ID:** `26034` | **Smart India Hackathon**

[![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-teal?logo=fastapi)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)](https://postgresql.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-6+-green?logo=mongodb)](https://mongodb.com)
[![HuggingFace](https://img.shields.io/badge/HuggingFace-BERT%20%2B%20ViT-yellow?logo=huggingface)](https://huggingface.co)
[![Hyperledger](https://img.shields.io/badge/Hyperledger-Fabric-lightgrey?logo=hyperledger)](https://hyperledger.org)

---

## 📖 Table of Contents

- [What is PARAKH?](#-what-is-parakh)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [AI Pipeline](#-ai--computer-vision-pipeline)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Mobile Screens](#-mobile-app--screens)
- [Quick Start](#-quick-start)
- [Environment Variables](#-environment-variables)
- [API Endpoints](#-api-endpoints)
- [Security](#-security-architecture)
- [Roles & Permissions](#-roles--permissions)
- [Legal Framework](#-legal--regulatory-framework)
- [Deployment](#-deployment)
- [Documentation](#-documentation-index)

---

## 🎯 What is PARAKH?

PARAKH automates product label compliance verification for enforcement officers under the **Legal Metrology Act, 2009** and the **Packaged Commodities Rules, 2011**.

A field inspector scans product packaging with their mobile device. PARAKH then runs a full AI pipeline:

| # | Step | Technology |
|---|------|------------|
| 1 | 📸 Captures label via AR-guided camera | Flutter + ARCore |
| 2 | 🔤 Extracts all text from packaging | Google Cloud Vision OCR |
| 3 | 🧠 Identifies MRP, quantity, manufacturer, dates | BERT Named Entity Recognition |
| 4 | ✅ Validates all 14 mandatory declarations | Custom Compliance Rule Engine |
| 5 | 🔍 Detects tampered labels & overprinted MRPs | Vision Transformer (ViT) |
| 6 | 📊 Scores non-compliance probability | Gradient Boosting Classifier |
| 7 | 🔗 Commits SHA-256 evidence to blockchain | Hyperledger Fabric |
| 8 | 📄 Generates reports in PDF, JSON, CSV | ReportLab + Crypto |

---

## ✨ Key Features

### 👮 For Inspectors
| Feature | Description |
|---------|-------------|
| 📸 **AR-Guided Camera** | Real-time label detection with live overlay bounding boxes |
| 🔍 **Barcode Scanner** | GS1 Modulo-10 checksum validation + Open Food Facts lookup |
| 🤖 **AI Compliance Check** | One-tap OCR → NER → Rule Engine → Anomaly Detection |
| 📋 **Establishment Intake** | Structured form with GPS auto-fill and photo capture |
| 📄 **Multi-Format Reports** | PDF (digital signature), JSON, CSV export |
| 🔗 **Blockchain Evidence** | SHA-256 hash committed to Hyperledger Fabric |
| 📶 **Offline Mode** | Full functionality without connectivity; auto-syncs on reconnect |

### 🏢 For Nodal Officers
| Feature | Description |
|---------|-------------|
| 🗺️ **Violation Heatmaps** | Geographic cluster view of non-compliance hotspots |
| ✅ **Verification Queue** | Review, approve or return inspector-submitted evidence |
| 📈 **Analytics Dashboard** | Inspection volume, compliance rates, pending cases |

### 🏛️ For Commissioners
| Feature | Description |
|---------|-------------|
| 🏢 **State-Wide Analytics** | Aggregated statistics across all districts |
| 📜 **Legal Notice Generation** | Auto-filled PDF legal notices for violations |
| 🔍 **Audit Trail** | Complete system log with timestamp, actor, and action |

### 👤 For Citizens
| Feature | Description |
|---------|-------------|
| 📱 **Product Verification** | Scan barcodes to verify product authenticity |
| 📝 **Complaint Filing** | Submit complaints with photo evidence |
| 💬 **WhatsApp Channel** | Report violations via WhatsApp Business API |

---

## 🧩 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   MOBILE CLIENT (Flutter 3.x)                   │
│        18 Screens · ARCore/ARKit · GPS · Biometric Auth         │
└───────────────────────────┬─────────────────────────────────────┘
                            │  HTTPS / JWT
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  BACKEND (FastAPI + Uvicorn)                     │
│                                                                  │
│   ┌───────────────┐  ┌─────────────┐  ┌──────────────────────┐  │
│   │ Auth + RBAC   │  │ 15 Routers  │  │ SlowAPI Rate Limiter │  │
│   │ JWT + Argon2  │  │ API Gateway │  │ Per-endpoint limits  │  │
│   └───────────────┘  └─────────────┘  └──────────────────────┘  │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐   │
│   │              AI / COMPUTER VISION PIPELINE               │   │
│   │  OpenCV → Cloud Vision OCR → BERT NER → Rule Engine     │   │
│   │  → ViT Anomaly Detector → Risk Predictor                │   │
│   │  → SHA-256 Evidence Hash → Blockchain Commit             │   │
│   └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌──────────────────┐  ┌────────────────┐  ┌───────────────┐   │
│   │  PostgreSQL 15+  │  │  MongoDB 6+    │  │  MinIO/Local  │   │
│   │  Relational +    │  │  AI Logs +     │  │  Images +     │   │
│   │  Cache + Queue   │  │  Raw OCR Dump  │  │  Evidence     │   │
│   └──────────────────┘  └────────────────┘  └───────────────┘   │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐   │
│   │    Hyperledger Fabric · NIC MeghRaj (Govt Cloud)         │   │
│   │    Tamper-proof evidence ledger for legal admissibility   │   │
│   └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧠 AI / Computer Vision Pipeline

```
Raw Image
    │
    ▼  image_processor.py (OpenCV)
    │  • CLAHE contrast enhancement
    │  • 3D surface unwarping
    │  • Canny edge detection & ROI crop
    │  • Perspective transform
    │
    ▼  ocr_engine.py (Google Cloud Vision)
    │  • Full-text extraction
    │  • Word-level bounding boxes
    │  • Confidence scores per word
    │
    ▼  nlp_extractor.py (BERT dslim/bert-base-NER)
    │  • Extracts: MRP, Net Quantity, Mfg Date,
    │    Expiry Date, Manufacturer, Consumer Care
    │
    ▼  rules/engine.py (8-Rule Compliance Engine)
    │  • MRP Rule        • Date Rule
    │  • Quantity Rule   • Font Size Rule
    │  • Manufacturer    • Consumer Care
    │  • OFF Cross-Ref   • GS1 Rule
    │
    ▼  anomaly_detector.py (ViT google/vit-base-patch16-224)
    │  • HSV color consistency
    │  • MSER typography check
    │  • Laplacian logo quality
    │  • ViT feature entropy analysis
    │
    ▼  predictive.py (scikit-learn GradientBoostingClassifier)
    │  • Outputs: risk score 0.0 – 1.0
    │
    ▼  evidence_chain.py (Blockchain)
       SHA-256 (Image + GPS + Timestamp + OCR + Violations)
       → PostgreSQL → MongoDB → Hyperledger Fabric
```

---

## 🛠️ Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| 📱 **Mobile** | Flutter + ARCore/ARKit | 3.x |
| 🔄 **State Management** | Provider Pattern | 6.x |
| ⚡ **Backend API** | Python FastAPI + Uvicorn | 0.115 |
| 🔤 **OCR** | Google Cloud Vision API | 3.9 |
| 🧠 **NLP / NER** | HuggingFace `dslim/bert-base-NER` | 4.47 |
| 🖼️ **Computer Vision** | OpenCV | 4.10 |
| 🔍 **Anomaly Detection** | HuggingFace ViT `google/vit-base-patch16-224` | 1.0 |
| 📊 **Predictive Analytics** | scikit-learn GradientBoosting | 1.6 |
| 🗄️ **Primary Database** | PostgreSQL + asyncpg | 15+ |
| 📦 **Cache & Queue** | PostgreSQL-native (no Redis) | 15+ |
| 📝 **NoSQL / Logs** | MongoDB + Motor async | 6+ |
| 🗂️ **Object Storage** | MinIO (S3-compat) or Local FS | Latest |
| 🔗 **Blockchain** | Hyperledger Fabric · NIC MeghRaj | — |
| 🌐 **Product Registry** | Open Food Facts API | v2 |
| 💬 **Messaging** | WhatsApp Business API | v18 |
| 🔒 **Auth** | JWT HS256 + Argon2/BCrypt | — |
| ⚡ **Rate Limiting** | SlowAPI | 0.1.10 |

---

## 📁 Project Structure

```
T1/
├── README.md                            ← You are here
│
├── backend/                             🖥️  Python FastAPI Backend
│   ├── README.md
│   ├── app/
│   │   ├── main.py                      App entry point (Uvicorn)
│   │   ├── config.py                    Pydantic BaseSettings
│   │   │
│   │   ├── ai/                          🧠 AI Pipeline (6 modules)
│   │   │   ├── image_processor.py       OpenCV: CLAHE, unwarping
│   │   │   ├── ocr_engine.py            Google Cloud Vision OCR
│   │   │   ├── nlp_extractor.py         BERT NER extraction
│   │   │   ├── anomaly_detector.py      ViT anomaly detection
│   │   │   ├── predictive.py            Risk scoring
│   │   │   └── ai_triage.py             Queue prioritization
│   │   │
│   │   ├── api/v1/                      🔌 15 REST API Routers
│   │   │   ├── auth.py                  Login, register
│   │   │   ├── scan.py                  Upload + barcode lookup
│   │   │   ├── analysis.py              AI compliance pipeline
│   │   │   ├── inspections.py           CRUD + PDF/JSON/CSV export
│   │   │   ├── evidence.py              Blockchain commit/verify
│   │   │   ├── citizen.py               Complaints + WhatsApp
│   │   │   ├── analytics.py             Dashboard stats
│   │   │   ├── heatmaps.py              Violation clusters
│   │   │   ├── legal_notices.py         PDF legal notice
│   │   │   ├── audit.py                 Audit trail
│   │   │   └── ...
│   │   │
│   │   ├── rules/                       ⚖️ Compliance Rule Engine
│   │   │   ├── engine.py                Rule orchestrator
│   │   │   ├── mrp_rule.py
│   │   │   ├── date_rule.py
│   │   │   ├── net_quantity_rule.py
│   │   │   ├── font_size_rule.py
│   │   │   ├── manufacturer_rule.py
│   │   │   ├── consumer_care_rule.py
│   │   │   └── openfoodfacts_rule.py
│   │   │
│   │   ├── blockchain/                  🔗 Hyperledger Fabric
│   │   ├── core/                        🔒 Security, RBAC, Rate Limiter
│   │   ├── db/                          🗄️ PostgreSQL + MongoDB
│   │   ├── integrations/                🌐 Open Food Facts, WhatsApp
│   │   ├── models/                      📝 SQLAlchemy ORM (7 tables)
│   │   ├── repositories/               📂 Data Access Layer
│   │   ├── services/                    ⚙️ Business Logic (11 services)
│   │   └── storage/                     🗂️ MinIO + Local FS
│   │
│   ├── tests/                           🧪 37 Tests
│   ├── requirements.txt                 93 packages
│   └── .env.example                     50+ env vars
│
├── frontend/                            📱 Flutter Mobile App
│   ├── README.md
│   ├── lib/
│   │   ├── main.dart                    App entry + routes
│   │   ├── core/                        🎨 Foundation
│   │   │   ├── theme.dart               Material 3 design system
│   │   │   ├── api_client.dart          HTTP client + JWT
│   │   │   ├── constants.dart           API URLs, constants
│   │   │   ├── role_guard.dart          RBAC UI gatekeeper
│   │   │   └── storage_service.dart     Secure storage
│   │   ├── models/models.dart           Dart data models
│   │   ├── providers/                   State management (4 providers)
│   │   ├── screens/                     📱 18 Application Screens
│   │   └── widgets/                     🧩 6 Reusable Components
│   ├── assets/                          Logo SVG/PNG, splash video
│   └── pubspec.yaml
│
└── tools/                               📚 Docs, Scripts & Resources
    ├── LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md
    ├── USER_TYPES_AND_ROLES.md
    ├── Project_PARAKH_AI_Architecture.md
    ├── Project_PARAKH_Architecture.md
    ├── Project_PARAKH_Legal_Metrology_Rules.md
    ├── Project_PARAKH_Security_Layer.md
    ├── legal_metrology_rules_2011.json   Machine-readable rules DB
    ├── connect_device.ps1                ADB connectivity script
    └── splash_video.mp4
```

---

## 📱 Mobile App — Screens

### Navigation Flow

```
App Launch
    │
    ▼
Splash Screen (Video Animation)
    │
    ▼
Login Screen (Biometric + JWT)
    │
    ▼
Role Router ──────────────────────────────────────────────────────┐
    │                    │                    │                   │
    ▼                    ▼                    ▼                   ▼
👮 Inspector        🏢 Nodal          🏛️ Commissioner       👤 Citizen
 Dashboard           Dashboard            Dashboard            Dashboard
    │                    │                    │                   │
    ├─ AR Camera         ├─ Verifier          └─ Portal           └─ Verify
    ├─ Barcode           │    Queue               (Legal               Barcode
    ├─ AI Review         └─ Analytics              Notices +
    ├─ Verdict                                      Audit)
    ├─ Report
    ├─ Intake
    ├─ History
    └─ Offline Sync
```

### All 18 Screens

#### Common
| # | Screen | File | Description |
|---|--------|------|-------------|
| 1 | 🎬 Splash | `splash_screen.dart` | Video animation, auto-navigate |
| 2 | 🔑 Login | `login_screen.dart` | Biometric + credential auth |
| 3 | ⚙️ Profile | `profile_settings_screen.dart` | Settings, biometric toggle, logout |
| 4 | 🔀 Router | `dashboard_screen.dart` | Routes to role dashboard |

#### 👮 Inspector (9 screens)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 5 | 📊 Dashboard | `inspector_dashboard_screen.dart` | Metrics, violations, quick actions |
| 6 | 📸 AR Camera | `ar_camera_screen.dart` | ARCore live scanning with overlays |
| 7 | 🔍 Barcode | `barcode_scanner_screen.dart` | GS1 scan + Open Food Facts |
| 8 | 🤖 AI Review | `ai_review_screen.dart` | Image vs extracted fields |
| 9 | ✅ Verdict | `compliance_verdict_screen.dart` | Pass/Fail per declaration |
| 10 | 📄 Report | `evidence_report_screen.dart` | PDF/JSON/CSV + blockchain hash |
| 11 | 📋 Intake | `establishment_intake_screen.dart` | Establishment form + GPS |
| 12 | 📜 History | `inspection_history_screen.dart` | Searchable past inspections |
| 13 | 📶 Sync | `offline_sync_hub_screen.dart` | Offline queue + conflict resolve |

#### 🏢 Nodal Officer (2 screens)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 14 | 📋 Dashboard | `nodal_dashboard_screen.dart` | District metrics, pending queue |
| 15 | ✅ Verifier | `nodal_verifier_screen.dart` | Approve/reject evidence |

#### 🏛️ Commissioner (2 screens)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 16 | 📊 Dashboard | `commissioner_dashboard_screen.dart` | State analytics, heatmaps |
| 17 | 🏛️ Portal | `commissioner_portal_screen.dart` | Legal notices + audit trail |

#### 👤 Citizen (1 screen)
| # | Screen | File | Description |
|---|--------|------|-------------|
| 18 | 👤 Dashboard | `citizen_dashboard_screen.dart` | Verify products, file complaints |

---

## 🚀 Quick Start

### Prerequisites

| Requirement | Min Version | Notes |
|------------|-------------|-------|
| Python | 3.11+ | Backend runtime |
| Flutter SDK | 3.x | Mobile app |
| PostgreSQL | 15+ | Primary database |
| MongoDB | 6+ | AI logs storage |
| MinIO | Latest | Optional — can use local FS |
| Google Cloud Vision Key | — | Optional — for live OCR |

### 1. Clone

```bash
git clone https://github.com/jitendrachoudhary1401-hue/Parakh.git
cd Parakh/models/T1
```

### 2. Backend Setup

```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
cp .env.example .env         # ⚠️ Edit with your credentials

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**API available at:**
- Swagger UI → `http://localhost:8000/docs`
- Health check → `http://localhost:8000/api/v1/health`

> See [`backend/README.md`](backend/README.md) for detailed backend setup.

### 3. Mobile App Setup

```bash
cd frontend
flutter pub get
flutter run
```

Update your backend IP in `lib/core/constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_IP:8000/api/v1';
// Android emulator: use 10.0.2.2
```

> See [`frontend/README.md`](frontend/README.md) for detailed mobile setup.

---

## ⚙️ Environment Variables

Full template: [`backend/.env.example`](backend/.env.example)

| Category | Key Variables |
|----------|--------------|
| **App** | `APP_ENV`, `DEBUG`, `HOST`, `PORT`, `WORKERS` |
| **PostgreSQL** | `DATABASE_URL`, `DATABASE_URL_SYNC`, `DB_POOL_SIZE` |
| **MongoDB** | `MONGODB_URL`, `MONGODB_DATABASE` |
| **Auth** | `JWT_SECRET_KEY` ⚠️, `JWT_ALGORITHM`, `ENCRYPTION_KEY` ⚠️ |
| **AI/ML** | `GOOGLE_CLOUD_VISION_KEY`, `NER_MODEL_NAME`, `VIT_MODEL_NAME` |
| **Storage** | `STORAGE_PROVIDER`, `MINIO_ENDPOINT_URL`, `LOCAL_STORAGE_PATH` |
| **Blockchain** | `BLOCKCHAIN_ENABLED`, `BLOCKCHAIN_ENDPOINT` |
| **Rate Limits** | `RATE_LIMIT_LOGIN` (5/min), `RATE_LIMIT_UPLOAD` (20/min) |

> ⚠️ **MUST CHANGE:** `JWT_SECRET_KEY` and `ENCRYPTION_KEY` before any deployment.
>
> Generate secret: `python -c "import secrets; print(secrets.token_urlsafe(64))"`

---

## 📊 API Endpoints

All endpoints prefixed with `/api/v1`. Full interactive docs at `/docs`.

| Module | Method | Endpoint | Auth | Description |
|--------|:------:|----------|:----:|-------------|
| **Health** | GET | `/health` | — | Liveness probe |
| **Health** | GET | `/ready` | — | Readiness probe |
| **Auth** | POST | `/auth/login` | — | JWT login |
| **Auth** | POST | `/auth/register` | — | User registration |
| **Users** | GET | `/users/me` | JWT | Current user profile |
| **Scan** | POST | `/scan/upload` | JWT | Upload product image |
| **Scan** | POST | `/scan/process` | JWT | Trigger AI pipeline |
| **Scan** | GET | `/scan/barcode/{gtin}` | — | Public barcode lookup |
| **Analysis** | POST | `/analysis/{id}/verify` | JWT | Full AI compliance check |
| **Compliance** | GET | `/compliance/{id}` | JWT | Rule engine results |
| **Inspections** | GET | `/inspections` | JWT | List inspections |
| **Inspections** | POST | `/inspections` | JWT | Create inspection |
| **Inspections** | GET | `/inspections/{id}/export/pdf` | JWT | Export PDF |
| **Inspections** | GET | `/inspections/{id}/export/json` | JWT | Export JSON |
| **Inspections** | GET | `/inspections/{id}/export/csv` | JWT | Export CSV |
| **Evidence** | POST | `/evidence/commit` | JWT | Commit to blockchain |
| **Evidence** | GET | `/evidence/verify` | JWT | Verify integrity |
| **Citizen** | POST | `/citizen/report` | JWT | Submit complaint |
| **Citizen** | POST | `/citizen/whatsapp` | — | WhatsApp webhook |
| **Analytics** | GET | `/analytics/summary` | JWT | Dashboard stats |
| **Heatmaps** | GET | `/heatmaps` | JWT | Violation clusters |
| **Legal** | POST | `/legal-notices/generate` | JWT | Generate PDF notice |
| **Audit** | GET | `/audit/logs` | JWT | Audit trail |
| **Sync** | POST | `/sync/push` | JWT | Push offline records |
| **Sync** | GET | `/sync/pull` | JWT | Pull latest records |

---

## 🔐 Security Architecture

```
Authentication Flow
───────────────────
[Mobile App] ──── Biometric / Password ──►
                                          [Login Endpoint]
                                              │
                                        Argon2 hash verify
                                              │
                                        JWT Token issued
                                              │
                    ◄──── access_token + refresh_token ────

Every Protected Request
────────────────────────
[Mobile App]
  │  Authorization: Bearer <token>
  ▼
[SlowAPI Rate Limiter]  ──► 429 Too Many Requests
  │
[JWT Verification]  ──► 401 Unauthorized
  │
[RBAC Role Check]  ──► 403 Forbidden
  │
[MIME + Magic Byte Validation]  ──► 422 Invalid File
  │
[Business Logic + AES-256 Encryption at rest]
  │
[Evidence: SHA-256 → Hyperledger Fabric]
```

| Layer | Technology | Detail |
|-------|-----------|--------|
| **Auth** | JWT HS256 | 30-min access token, 7-day refresh |
| **Password** | Argon2 + BCrypt | Argon2 primary, BCrypt fallback |
| **Biometrics** | `local_auth` Flutter | Fingerprint / Face ID |
| **RBAC (Frontend)** | `RoleGuard` | Gates every protected screen |
| **RBAC (Backend)** | `deps.py` | Enforces role on every endpoint |
| **Encryption** | AES-256 | Sensitive data at rest |
| **Evidence** | SHA-256 | `image + GPS + timestamp + OCR + violations` |
| **Blockchain** | Hyperledger Fabric | Tamper-proof legal admissibility |
| **File Validation** | MIME + magic bytes | Max 25 MB, JPEG/PNG/WebP only |

---

## 👥 Roles & Permissions

| Feature | 👮 Inspector | 🏢 Nodal | 🏛️ Commissioner | 👤 Citizen |
|---------|:-----------:|:--------:|:---------------:|:---------:|
| Scan (Camera / AR) | ✅ | ❌ | ❌ | ❌ |
| Barcode Lookup | ✅ | ✅ | ✅ | ✅ |
| AI Compliance Check | ✅ | ❌ | ❌ | ❌ |
| Submit Evidence | ✅ | ❌ | ❌ | ❌ |
| Establishment Intake | ✅ | ❌ | ❌ | ❌ |
| Generate Reports | ✅ | ✅ | ✅ | ❌ |
| Inspection History | ✅ | ✅ | ✅ | ❌ |
| Verify / Approve Evidence | ❌ | ✅ | ✅ | ❌ |
| District Analytics | ❌ | ✅ | ✅ | ❌ |
| State-Wide Analytics | ❌ | ❌ | ✅ | ❌ |
| Generate Legal Notices | ❌ | ❌ | ✅ | ❌ |
| View Audit Trail | ❌ | ❌ | ✅ | ❌ |
| File Complaints | ❌ | ❌ | ❌ | ✅ |
| WhatsApp Reporting | ❌ | ❌ | ❌ | ✅ |
| Offline Sync | ✅ | ❌ | ❌ | ❌ |

> Full RBAC matrix → [`tools/USER_TYPES_AND_ROLES.md`](tools/USER_TYPES_AND_ROLES.md)

---

## 📜 Legal & Regulatory Framework

| Legislation | Relevance |
|------------|-----------|
| **Legal Metrology Act, 2009** | Primary governing statute for enforcement |
| **Packaged Commodities Rules, 2011** (Amd. 2017) | 14 mandatory declarations on packaged goods |
| **Section 65B, Indian Evidence Act** | Electronic evidence admissibility in court |
| **IT Act, 2000** | Digital signatures and data protection |
| **Consumer Protection Act, 2019** | Citizen complaint handling framework |
| **BIS Standards IS 15778 / IS 14543** | Unit of measurement & date format standards |

> Full compliance checklist → [`tools/LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md`](tools/LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md)

---

## 🚢 Deployment

### Local Development

```bash
# Terminal 1 — Backend
cd backend && uvicorn app.main:app --reload --port 8000

# Terminal 2 — Mobile App
cd frontend && flutter run
```

### Docker

```bash
docker build -t parakh-backend ./backend
docker run -d --name parakh-api -p 8000:8000 --env-file backend/.env parakh-backend
```

### Production Checklist

- [ ] `APP_ENV=production` and `DEBUG=false`
- [ ] Rotate `JWT_SECRET_KEY` and `ENCRYPTION_KEY`
- [ ] PostgreSQL with SSL + PgBouncer connection pooling
- [ ] Enable `BLOCKCHAIN_ENABLED=true` with NIC credentials
- [ ] HTTPS reverse proxy (Nginx / Traefik)
- [ ] Disable Swagger: `/docs` and `/redoc` hidden in production
- [ ] `AUDIT_LOG_ENABLED=true`
- [ ] Mobile release build: `flutter build apk --release`

---

## 📄 Documentation Index

### Regulatory & Compliance
| Document | Description |
|----------|-------------|
| [Compliance Checklist](tools/LEGAL_METROLOGY_COMPLIANCE_CHECKLIST.md) | PCR 2011 — all 14 mandatory declarations with Schedule I/II |
| [User Types & Roles](tools/USER_TYPES_AND_ROLES.md) | Full RBAC matrix, role definitions, segregation of duties |
| [Legal Metrology Rules](tools/Project_PARAKH_Legal_Metrology_Rules.md) | Rule definitions and penalty framework |
| [Advanced Features](tools/Advanced_Legal_Metrology_Features.md) | Extended compliance and edge-case handling |

### Technical Architecture
| Document | Description |
|----------|-------------|
| [AI Architecture](tools/Project_PARAKH_AI_Architecture.md) | AI/ML pipeline design and model selection rationale |
| [AI Models](tools/Project_PARAKH_AI_Models.md) | Model specs, training data, benchmarks |
| [System Architecture](tools/Project_PARAKH_Architecture.md) | Backend architecture and data flow |
| [API Gateway](tools/Project_PARAKH_API_Gateway.md) | Gateway config and routing |
| [Security Layer](tools/Project_PARAKH_Security_Layer.md) | Security architecture and threat model |
| [Tech Stack](tools/Project_PARAKH_TechStack.md) | Technology decisions and rationale |

### Product & Integration
| Document | Description |
|----------|-------------|
| [PRD](tools/Project_PARAKH_PRD.md) | Product Requirements Document |
| [API Documentation](tools/Project_PARAKH_Documentation.md) | API reference and integration guide |
| [Mobile App Pages](tools/Project_PARAKH_Mobile_App_Pages.md) | Screen inventory and navigation map |
| [Device Connectivity](tools/DEVICE_CONNECTIVITY_GUIDE.md) | Android/iOS device connection guide |
| [Setup Instructions](tools/INSTRUCTIONS.md) | Detailed setup and configuration |

---

## 📝 License

Developed for the **Government of India** under the Smart India Hackathon initiative. All rights reserved under applicable government licensing terms.

---

> **🏛️ Project PARAKH** — *Protecting Consumers. Empowering Enforcement. Powered by AI.*
>
> Ministry of Consumer Affairs, Food & Public Distribution (DoCA) | Government of India
