# 🏛️ Project PARAKH

### **Product Analysis & Regulatory Assessment for Known Hazards**

> An AI-powered Legal Metrology enforcement platform built for the **Ministry of Consumer Affairs, Food & Public Distribution (DoCA), Government of India**.
>
> **Problem Statement ID:** 26034 | **Smart India Hackathon**

---

## 🎯 What is PARAKH?

PARAKH automates product label compliance verification for enforcement officers under the **Legal Metrology Act, 2009** and the **Packaged Commodities Rules, 2011**. Field inspectors scan product packaging using a mobile device; the system then uses **AI, Computer Vision, and NLP** to extract label declarations, cross-reference against regulatory databases, flag violations, generate cryptographic evidence, and commit tamper-proof records to a government blockchain.

---

## 🧩 System Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    MOBILE / EDGE CLIENT                       │
│         Flutter + ARCore/ARKit + Camera + GPS                 │
│   (11 Screens: Splash, Login, Dashboard, AR Scan, Barcode,   │
│    AI Review, Compliance Verdict, Evidence, Sync, History,    │
│    Profile Settings)                                          │
└────────────────────────┬──────────────────────────────────────┘
                         │ REST API (HTTPS)
                         ▼
┌───────────────────────────────────────────────────────────────┐
│                     BACKEND (FastAPI)                          │
│  ┌─────────────┐ ┌──────────────┐ ┌────────────────────────┐ │
│  │ Auth & RBAC │ │ API Gateway  │ │  Rate Limiter          │ │
│  │ (JWT+Argon2)│ │ (14 Routers) │ │  (SlowAPI)             │ │
│  └─────────────┘ └──────┬───────┘ └────────────────────────┘ │
│                          │                                    │
│  ┌───────────────────────▼────────────────────────────────┐  │
│  │              AI / COMPUTER VISION PIPELINE              │  │
│  │  OpenCV → Cloud Vision OCR → HuggingFace NLP (NER)     │  │
│  │  → Compliance Rule Engine → ViT Anomaly Detector       │  │
│  │  → SHA-256 Evidence Hash → Blockchain Commit            │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌──────────────────┐ ┌────────────────┐ ┌────────────────┐  │
│  │   PostgreSQL     │ │    MongoDB     │ │  MinIO / Local │  │
│  │ (Relational +    │ │ (AI Logs,      │ │ (Image Storage)│  │
│  │  Cache + Queue)  │ │  Raw OCR Dump) │ │                │  │
│  └──────────────────┘ └────────────────┘ └────────────────┘  │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │         Hyperledger Fabric (NIC MeghRaj Cloud)           │ │
│  │    Tamper-proof evidence ledger for legal admissibility   │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Mobile/Edge** | Flutter 3.x + ARCore/ARKit + Camera + Geolocator + Biometric Auth |
| **Backend** | Python 3.11+ / FastAPI / Uvicorn |
| **OCR** | Google Cloud Vision API |
| **NLP** | HuggingFace Transformers (`dslim/bert-base-NER`) |
| **Computer Vision** | OpenCV 4.x (3D Unwarping, CLAHE, Contour Detection) |
| **Anomaly Detection** | HuggingFace ViT (`google/vit-base-patch16-224`) |
| **Predictive Analytics** | scikit-learn (`GradientBoostingClassifier`) |
| **Relational DB** | PostgreSQL 15+ (asyncpg) |
| **Cache & Task Queue** | PostgreSQL-native (no Redis dependency) |
| **NoSQL / AI Logs** | MongoDB (Motor async driver) |
| **Object Storage** | MinIO (S3-compatible) or Local Filesystem |
| **Blockchain** | Hyperledger Fabric on NIC MeghRaj (Govt. of India Cloud) |
| **Integrations** | Open Food Facts API, WhatsApp Business API |
| **Auth** | JWT (HS256) + Argon2/BCrypt password hashing |
| **Testing** | pytest + pytest-asyncio (37 unit & integration tests) |

---

## 📁 Project Structure

```
T1/
├── backend/                 # Python FastAPI Backend
│   ├── app/
│   │   ├── ai/              # AI Engines (OCR, NLP, ViT, OpenCV, Predictive, Triage)
│   │   ├── api/v1/          # 14 REST API Routers
│   │   ├── blockchain/      # Hyperledger Fabric Client & Evidence Chain
│   │   ├── core/            # Security, RBAC, Rate Limiter, PG Cache & Queue
│   │   ├── db/              # PostgreSQL & MongoDB connectors
│   │   ├── integrations/    # Open Food Facts, WhatsApp Business API
│   │   ├── models/          # SQLAlchemy ORM Models
│   │   ├── repositories/    # Data Access Layer
│   │   ├── rules/           # Legal Metrology Compliance Rule Engine
│   │   ├── schemas/         # Pydantic Request/Response Schemas
│   │   ├── services/        # Business Logic Layer
│   │   └── storage/         # MinIO & Local File Storage
│   ├── tests/               # 37 Unit & Integration Tests
│   ├── requirements.txt
│   └── .env.example
│
├── frontend/                # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/            # Theme, API Client, Constants, Secure Storage
│   │   ├── models/          # Dart Data Models
│   │   ├── providers/       # State Management (Provider pattern)
│   │   ├── screens/         # 11 Application Screens
│   │   └── widgets/         # 6 Reusable UI Components
│   ├── assets/              # Logo SVG/PNG, Splash Video
│   ├── android/             # Android Platform Config
│   ├── ios/                 # iOS Platform Config
│   └── pubspec.yaml
│
└── tools/                   # Documentation & Architecture
    ├── Project_PARAKH_AI_Architecture.md
    ├── Project_PARAKH_Architecture.md
    ├── Project_PARAKH_Documentation.md
    ├── Project_PARAKH_PRD.md
    ├── Project_PARAKH_Security_Layer.md
    ├── Project_PARAKH_TechStack.md
    └── Project_PARAKH_Mobile_App_Pages.md
```

---

## 🚀 Quick Start

### Prerequisites

* Python 3.11+ with `pip`
* Flutter 3.x SDK
* PostgreSQL 15+
* MongoDB 6+
* (Optional) MinIO for object storage
* (Optional) Google Cloud Vision API key for live OCR

### 1. Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env       # Edit .env with your credentials
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Mobile App Setup

```bash
cd frontend
flutter pub get
flutter run                # Launches on connected device or emulator
```

### 3. Run Tests

```bash
cd backend
python -m pytest           # Expected: 37 passed
```

---

## 🔐 Security Architecture

* **Authentication**: OAuth2-compliant JWT (HS256) with Argon2/BCrypt password hashing
* **Authorization**: Role-Based Access Control (`inspector`, `admin`, `citizen`)
* **Rate Limiting**: Per-endpoint SlowAPI rate limiting (login: 5/min, upload: 20/min)
* **File Validation**: MIME-type verification, magic-byte checking, max 25MB upload
* **Evidence Integrity**: SHA-256 hash of (Image + GPS + Timestamp + OCR + Violations) committed to Hyperledger Fabric
* **Encryption**: AES-256 encryption for sensitive data at rest

---

## 📊 API Endpoints

All endpoints are prefixed with `/api/v1`:

| Module | Endpoint | Description |
|---|---|---|
| Health | `GET /health`, `GET /ready` | Liveness & readiness probes |
| Auth | `POST /auth/login`, `POST /auth/register` | JWT authentication |
| Users | `GET /users/me`, `PUT /users/{id}` | User profile management |
| Scan | `POST /scan/upload`, `POST /scan/process` | Image upload & processing |
| Analysis | `POST /analysis/{id}/verify` | Full AI compliance pipeline |
| Inspections | `GET /inspections`, `POST /inspections` | Inspection CRUD |
| Compliance | `GET /compliance/{id}` | Rule engine results |
| Evidence | `POST /evidence/commit`, `GET /evidence/verify` | Blockchain evidence |
| Citizen | `POST /citizen/report`, `POST /citizen/whatsapp` | Public complaint portal |
| Analytics | `GET /analytics/summary` | Dashboard analytics |
| Heatmaps | `GET /heatmaps` | Geographic violation clusters |
| Legal Notices | `POST /legal-notices/generate` | PDF legal notice generation |
| Audit | `GET /audit/logs` | System audit trail |
| Sync | `POST /sync/push`, `GET /sync/pull` | Offline data synchronization |

---

## 📜 Legal & Regulatory Framework

This system enforces compliance with:

* **Legal Metrology Act, 2009** (Government of India)
* **Packaged Commodities Rules, 2011** (Amendment 2017)
* **Section 65B, Indian Evidence Act** (Electronic evidence admissibility)
* **IT Act, 2000** (Digital signature and data protection)
* **Consumer Protection Act, 2019** (Citizen complaint handling)

---

## 👥 Roles & Permissions

| Role | Capabilities |
|---|---|
| **Inspector** | Scan products, run compliance checks, commit evidence, generate notices |
| **Admin** | All inspector capabilities + user management, analytics, audit logs |
| **Citizen** | Submit complaints via app or WhatsApp, track complaint status |

---

## 📄 Documentation

Detailed documentation is available in the `tools/` directory:

| Document | Description |
|---|---|
| [AI Architecture](tools/Project_PARAKH_AI_Architecture.md) | Complete AI/ML pipeline documentation |
| [System Architecture](tools/Project_PARAKH_Architecture.md) | Backend architecture & data flow |
| [Tech Stack](tools/Project_PARAKH_TechStack.md) | Technology decisions & rationale |
| [PRD](tools/Project_PARAKH_PRD.md) | Product Requirements Document |
| [Security Layer](tools/Project_PARAKH_Security_Layer.md) | Security architecture & threat model |
| [API Documentation](tools/Project_PARAKH_Documentation.md) | API reference & integration guide |
| [Mobile App Pages](tools/Project_PARAKH_Mobile_App_Pages.md) | Mobile screen inventory & navigation |

---

## 📝 License

This project is developed for the **Government of India** under the Smart India Hackathon initiative. All rights reserved under applicable government licensing terms.

---

> **Project PARAKH** — *Protecting Consumers. Empowering Enforcement. Powered by AI.*
