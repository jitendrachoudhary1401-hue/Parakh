# 🖥️ Project PARAKH — Backend

### Python FastAPI Backend for AI-Powered Legal Metrology Enforcement

---

## 📋 Overview

The PARAKH backend is a high-performance **Python FastAPI** application that orchestrates the complete AI compliance verification pipeline. It processes product label images through a multi-stage AI engine (OpenCV → Cloud Vision OCR → HuggingFace NLP → Rule Engine → ViT Anomaly Detector), generates cryptographic evidence hashes, and commits tamper-proof records to Hyperledger Fabric.

---

## 🏗️ Architecture

```
app/
├── ai/                        # AI & Computer Vision Engines
│   ├── ocr_engine.py          # Google Cloud Vision OCR integration
│   ├── nlp_extractor.py       # HuggingFace Transformers NER pipeline
│   ├── image_processor.py     # OpenCV preprocessing & 3D surface unwarping
│   ├── anomaly_detector.py    # HuggingFace ViT anomaly/counterfeit detector
│   ├── ai_triage.py           # AI citizen complaint triage classifier
│   └── predictive.py          # scikit-learn predictive risk analytics
│
├── api/v1/                    # REST API Endpoints (14 routers)
│   ├── router.py              # Master API v1 router aggregator
│   ├── health.py              # /health (liveness) & /ready (readiness)
│   ├── auth.py                # JWT login & registration
│   ├── users.py               # User profile CRUD
│   ├── scan.py                # Image upload & processing
│   ├── analysis.py            # Full AI compliance pipeline trigger
│   ├── inspections.py         # Inspection record management
│   ├── compliance.py          # Rule engine evaluation results
│   ├── evidence.py            # SHA-256 evidence hash & blockchain commit
│   ├── citizen.py             # Public citizen complaint & WhatsApp webhook
│   ├── analytics.py           # Dashboard summary analytics
│   ├── heatmaps.py            # Geographic violation cluster heatmaps
│   ├── legal_notices.py       # PDF legal notice generation
│   ├── audit.py               # System audit trail logs
│   └── sync.py                # Offline mobile data synchronization
│
├── blockchain/                # Hyperledger Fabric Integration
│   ├── fabric_client.py       # gRPC client for NIC MeghRaj Cloud
│   ├── evidence_chain.py      # SHA-256 payload hashing & ledger commit
│   └── verifier.py            # Evidence integrity verification
│
├── core/                      # Core Infrastructure
│   ├── security.py            # OAuth2 JWT, Argon2/BCrypt password hashing
│   ├── rbac.py                # Role-Based Access Control (inspector/admin/citizen)
│   ├── rate_limiter.py        # Per-endpoint SlowAPI rate limiting
│   ├── pg_cache.py            # PostgreSQL-native key-value cache (replaces Redis)
│   ├── pg_queue.py            # PostgreSQL-native task queue (SKIP LOCKED)
│   ├── middleware.py          # Request logging & error handling middleware
│   ├── exceptions.py          # Custom exception hierarchy
│   └── responses.py           # Standardized API response wrappers
│
├── db/                        # Database Connectors
│   ├── postgres.py            # SQLAlchemy async engine & session factory
│   └── mongodb.py             # Motor async MongoDB client
│
├── integrations/              # External API Clients
│   ├── openfoodfacts_client.py # Open Food Facts barcode lookup
│   ├── whatsapp_client.py     # WhatsApp Business API messaging
│   └── gs1_client.py          # GS1 lookup interface (bridges to OFF)
│
├── models/                    # SQLAlchemy ORM Models
│   ├── user.py                # User account with role & hashed password
│   ├── inspection.py          # Inspection record with GPS & image path
│   ├── evidence.py            # Blockchain evidence with SHA-256 hash
│   ├── gs1_product.py         # Open Food Facts cached product data
│   ├── audit_log.py           # System audit trail entries
│   ├── cache_entry.py         # PostgreSQL cache table (TTL key-value)
│   └── task_queue.py          # PostgreSQL task queue (job lifecycle)
│
├── repositories/              # Data Access Layer (Repository Pattern)
│   ├── inspection_repo.py
│   ├── evidence_repo.py
│   ├── gs1_repo.py
│   └── user_repo.py
│
├── rules/                     # Legal Metrology Compliance Rule Engine
│   ├── engine.py              # Rule orchestrator
│   ├── mrp_rule.py            # MRP declaration validation
│   ├── date_rule.py           # Manufacturing/Expiry date validation
│   ├── quantity_rule.py       # Net quantity declaration validation
│   ├── gs1_rule.py            # Manufacturer cross-reference vs. Open Food Facts
│   └── consumer_care_rule.py  # Consumer care contact validation
│
├── schemas/                   # Pydantic Request/Response Schemas
├── services/                  # Business Logic Layer
│   ├── analysis_service.py    # End-to-end AI pipeline orchestrator
│   ├── evidence_service.py    # Evidence packaging & blockchain commitment
│   ├── auth_service.py        # Authentication business logic
│   ├── scan_service.py        # Image upload & processing
│   ├── inspection_service.py  # Inspection lifecycle management
│   ├── citizen_service.py     # Citizen complaint handling
│   ├── legal_notice_service.py # PDF legal notice generation
│   ├── heatmap_service.py     # Geographic risk zone computation
│   ├── analytics_service.py   # Dashboard metric aggregation
│   ├── sync_service.py        # Offline data sync management
│   └── user_service.py        # User account management
│
├── storage/                   # Object Storage Abstraction
│   └── __init__.py            # MinIO (S3) & Local filesystem backends
│
├── config.py                  # Centralized pydantic-settings configuration
└── main.py                    # FastAPI application entry point

tests/                         # Test Suite (37 tests)
├── conftest.py                # Shared fixtures (async DB session, auth headers)
├── test_auth.py               # Authentication & JWT tests (5 tests)
├── test_citizen.py            # Citizen complaint tests (2 tests)
├── test_compliance.py         # Rule engine evaluation tests (3 tests)
├── test_evidence.py           # SHA-256 hash & evidence tests (2 tests)
├── test_gs1.py                # Open Food Facts integration tests (4 tests)
├── test_ocr.py                # OCR engine tests (4 tests)
├── test_pg_cache_queue.py     # PostgreSQL cache & queue tests (4 tests)
├── test_rules.py              # Legal Metrology rule tests (10 tests)
└── test_security.py           # File validation & security tests (3 tests)
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version |
|---|---|
| Python | 3.11+ |
| PostgreSQL | 15+ |
| MongoDB | 6+ |
| MinIO (optional) | Latest |
| Google Cloud Vision API key (optional) | For live OCR |

### Installation

```bash
# 1. Navigate to backend directory
cd backend

# 2. Create and activate virtual environment
python -m venv venv
# Linux/macOS:
source venv/bin/activate
# Windows:
venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
# Edit .env with your database credentials, API keys, etc.
```

### Database Setup

```bash
# Create PostgreSQL database
psql -U postgres -c "CREATE USER parakh_user WITH PASSWORD 'your_password';"
psql -U postgres -c "CREATE DATABASE parakh_db OWNER parakh_user;"

# Run Alembic migrations
alembic upgrade head
```

### Run Development Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/api/v1/health
- **Readiness Probe**: http://localhost:8000/api/v1/ready

### Run Tests

```bash
# Run all 37 tests
python -m pytest

# Run with verbose output
python -m pytest -v

# Run with coverage report
python -m pytest --cov=app --cov-report=term-missing
```

---

## 🔧 Environment Variables

All configuration is managed via environment variables (`.env` file). Key variables:

### Core Application
| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | `development`, `staging`, or `production` |
| `DEBUG` | `true` | Enable debug mode |
| `PORT` | `8000` | Server port |

### Databases
| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | `postgresql+asyncpg://...` | PostgreSQL async connection string |
| `MONGODB_URL` | `mongodb://localhost:27017` | MongoDB connection string |
| `USE_POSTGRES_CACHE` | `true` | Enable PostgreSQL-native caching |
| `USE_POSTGRES_QUEUE` | `true` | Enable PostgreSQL-native task queue |

### Authentication
| Variable | Default | Description |
|---|---|---|
| `JWT_SECRET_KEY` | — | **Required.** Random 64+ char secret |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | JWT access token expiry |

### AI / ML
| Variable | Default | Description |
|---|---|---|
| `GOOGLE_CLOUD_VISION_KEY` | — | Google Cloud Vision API key |
| `NER_MODEL_NAME` | `dslim/bert-base-NER` | HuggingFace NER model |
| `VIT_MODEL_NAME` | `google/vit-base-patch16-224` | HuggingFace ViT model |
| `ANOMALY_DETECTION_ENABLED` | `true` | Enable ViT anomaly detection |

### Integrations
| Variable | Default | Description |
|---|---|---|
| `OPENFOODFACTS_API_URL` | `https://world.openfoodfacts.org/api/v2` | Open Food Facts API |
| `WHATSAPP_ENABLED` | `false` | Enable WhatsApp Business API |
| `BLOCKCHAIN_ENABLED` | `false` | Enable Hyperledger Fabric |

See [`.env.example`](.env.example) for the complete list of all 50+ configurable variables.

---

## 🧠 AI Pipeline

The compliance verification pipeline runs through these stages:

```
1. OpenCV Preprocessing
   ├── Fast Non-Local Means Denoising
   ├── CLAHE Contrast Enhancement
   ├── Canny Edge Contour Detection & ROI Cropping
   ├── Hough Line Curved Surface Detection
   └── Perspective Transform 3D Unwarping

2. Google Cloud Vision OCR
   └── Raw text, word confidence, bounding box vertices, language detection

3. HuggingFace NLP Entity Extraction
   └── MRP, Net Quantity, Mfg Date, Expiry Date, Consumer Care, Manufacturer

4. Open Food Facts Cross-Reference
   └── Barcode lookup for registered manufacturer & product verification

5. Compliance Rule Engine
   ├── MRP Declaration Rule
   ├── Date Declaration Rule (Mfg + Expiry)
   ├── Net Quantity Rule
   ├── Consumer Care Contact Rule
   └── GS1 Manufacturer Cross-Reference Rule

6. ViT Anomaly Detection
   ├── HSV Color Consistency Analysis
   ├── MSER Typography Check
   ├── Laplacian Logo Quality Check
   └── ViT Feature Embedding Entropy Analysis

7. Evidence Hash (on violation)
   └── SHA-256(Image + GPS + Timestamp + OCR + Violations)
       → Stored in PostgreSQL + MongoDB + Hyperledger Fabric
```

---

## 🗄️ Database Schema

### PostgreSQL Tables
| Table | Purpose |
|---|---|
| `users` | User accounts with roles and hashed passwords |
| `inspections` | Inspection records with GPS, image paths, and results |
| `evidence` | Blockchain evidence with SHA-256 hashes and tx receipts |
| `openfoodfacts_products` | Cached barcode lookup results |
| `audit_logs` | System audit trail entries |
| `cache_entries` | PostgreSQL-native TTL key-value cache |
| `task_queue` | PostgreSQL-native background job queue |

### MongoDB Collections
| Collection | Purpose |
|---|---|
| `ai_extraction_logs` | Raw OCR dumps, NLP entities, bounding boxes, ViT findings |

---

## 🧪 Test Coverage

| Test File | Tests | Coverage Area |
|---|---|---|
| `test_auth.py` | 5 | JWT login, registration, token refresh, password hashing |
| `test_compliance.py` | 3 | Rule engine overall status evaluation |
| `test_rules.py` | 10 | Individual rule validations (MRP, dates, quantity, etc.) |
| `test_ocr.py` | 4 | OCR engine initialization and text extraction |
| `test_gs1.py` | 4 | Open Food Facts barcode lookup & caching |
| `test_evidence.py` | 2 | SHA-256 hash computation & evidence packaging |
| `test_citizen.py` | 2 | Citizen complaint submission & WhatsApp webhook |
| `test_pg_cache_queue.py` | 4 | PostgreSQL cache CRUD/expiration & task queue lifecycle |
| `test_security.py` | 3 | File validation, MIME checking, embedded script rejection |
| **Total** | **37** | **All passing** |

---

## 🔌 API Reference

### Authentication
```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "inspector@parakh.gov.in", "password": "SecurePass123!", "role": "inspector"}'

# Login and get JWT token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "inspector@parakh.gov.in", "password": "SecurePass123!"}'
```

### Scan & Analysis
```bash
# Upload product image
curl -X POST http://localhost:8000/api/v1/scan/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@product_label.jpg" \
  -F "latitude=28.6139" \
  -F "longitude=77.2090"

# Run full AI compliance check
curl -X POST http://localhost:8000/api/v1/analysis/<inspection_id>/verify \
  -H "Authorization: Bearer <token>" \
  -d '{"product_barcode": "8901234567890"}'
```

### Evidence
```bash
# Commit evidence to blockchain
curl -X POST http://localhost:8000/api/v1/evidence/commit \
  -H "Authorization: Bearer <token>" \
  -d '{"inspection_id": "<uuid>", "ocr_text_snapshot": "...", "violation_data": {...}}'

# Verify evidence integrity
curl -X GET http://localhost:8000/api/v1/evidence/<evidence_id>/verify \
  -H "Authorization: Bearer <token>"
```

---

## 🚢 Deployment

### Production (Render / Railway / VPS)

```bash
# Procfile
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 4
```

### Docker

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 📝 Development

```bash
# Code formatting
black app/ tests/

# Linting
ruff check app/ tests/

# Type checking
mypy app/

# Database migration
alembic revision --autogenerate -m "description"
alembic upgrade head
```
