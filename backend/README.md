# 🖥️ Project PARAKH — Backend
## Python FastAPI Backend for AI-Powered Legal Metrology Enforcement

[![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-teal?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)](https://postgresql.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-6+-green?logo=mongodb)](https://mongodb.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.5-red?logo=pytorch)](https://pytorch.org)
[![OpenCV](https://img.shields.io/badge/OpenCV-4.10-purple?logo=opencv)](https://opencv.org)

> Part of [Project PARAKH](../README.md) — Government of India

---

## 📋 Overview

The PARAKH backend is a high-performance **Python FastAPI** application that orchestrates:

- **15 REST API routers** — full enforcement workflow from login to blockchain commit
- **6-stage AI/CV pipeline** — OpenCV → Cloud Vision → BERT → Rules → ViT → Risk Score
- **8-rule compliance engine** — enforces all mandatory declarations under PCR 2011
- **Multi-database** — PostgreSQL (relational + cache + queue) + MongoDB (AI logs) + MinIO
- **Blockchain evidence** — SHA-256 hash committed to Hyperledger Fabric
- **Zero-Redis architecture** — PostgreSQL-native cache and task queue (SKIP LOCKED)

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                   15 REST API ROUTERS                        │
│  auth · users · scan · analysis · inspections · compliance   │
│  evidence · citizen · analytics · heatmaps · legal_notices   │
│  audit · sync · health                                       │
└────────────────────────────┬─────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────────┐
        │ Auth &   │  │ SlowAPI  │  │  Dependency   │
        │ RBAC     │  │  Rate    │  │  Injection    │
        │ (JWT +   │  │ Limiter  │  │  (deps.py)   │
        │ Argon2)  │  │          │  │               │
        └──────────┘  └──────────┘  └──────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│              SERVICES (Business Logic Layer)                  │
│  analysis · evidence · scan · inspection · citizen           │
│  legal_notice · heatmap · analytics · sync · user            │
└────────────┬──────────────────────────────┬──────────────────┘
             │                              │
             ▼                              ▼
┌───────────────────────┐       ┌───────────────────────────┐
│   AI PIPELINE         │       │   RULE ENGINE             │
│                       │       │                           │
│  1. image_processor   │       │  mrp_rule.py              │
│     (OpenCV CLAHE)    │       │  date_rule.py             │
│  2. ocr_engine        │       │  net_quantity_rule.py     │
│     (Cloud Vision)    │       │  font_size_rule.py        │
│  3. nlp_extractor     │       │  manufacturer_rule.py     │
│     (BERT NER)        │       │  consumer_care_rule.py    │
│  4. anomaly_detector  │       │  openfoodfacts_rule.py    │
│     (ViT)             │       │  gs1_rule.py              │
│  5. predictive.py     │       │                           │
│     (GradientBoost)   │       │  engine.py (orchestrator) │
│  6. ai_triage.py      │       │                           │
└───────────┬───────────┘       └───────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER                              │
│                                                              │
│  PostgreSQL 15+          MongoDB 6+         MinIO / Local    │
│  ─────────────           ────────────       ─────────────    │
│  users                   ai_extraction_     Images           │
│  inspections             logs (OCR dump,    Evidence files   │
│  evidence                NER entities,                       │
│  gs1_products            ViT findings)                       │
│  audit_logs                                                  │
│  cache_entries                                               │
│  task_queue                                                  │
│                                                              │
│  + Hyperledger Fabric (NIC MeghRaj) — blockchain evidence    │
└──────────────────────────────────────────────────────────────┘
```

---

## 📂 Directory Structure

```
backend/
├── app/
│   ├── main.py                       FastAPI app entry point (lifespan, middleware)
│   ├── config.py                     Pydantic BaseSettings (50+ env vars)
│   │
│   ├── ai/                           AI / Computer Vision Pipeline
│   │   ├── image_processor.py        OpenCV: CLAHE, 3D unwarp, contour, rotation fix
│   │   ├── ocr_engine.py             Google Cloud Vision: text, boxes, confidence
│   │   ├── nlp_extractor.py          BERT NER: MRP, quantity, dates, manufacturer
│   │   ├── anomaly_detector.py       ViT: tampered labels, overprinted MRPs
│   │   ├── predictive.py             GradientBoosting: risk score 0.0–1.0
│   │   └── ai_triage.py              Inspection queue prioritization
│   │
│   ├── api/
│   │   ├── deps.py                   Auth + DB session + RBAC dependencies
│   │   └── v1/
│   │       ├── router.py             Master router (mounts all sub-routers)
│   │       ├── auth.py               POST /auth/login, /auth/register
│   │       ├── users.py              GET /users/me, PUT /users/{id}
│   │       ├── scan.py               POST /scan/upload, GET /scan/barcode/{gtin}
│   │       ├── analysis.py           POST /analysis/{id}/verify
│   │       ├── inspections.py        CRUD + export PDF/JSON/CSV
│   │       ├── compliance.py         GET /compliance/{id}
│   │       ├── evidence.py           POST /evidence/commit, GET /evidence/verify
│   │       ├── citizen.py            POST /citizen/report, /citizen/whatsapp
│   │       ├── analytics.py          GET /analytics/summary
│   │       ├── heatmaps.py           GET /heatmaps
│   │       ├── legal_notices.py      POST /legal-notices/generate
│   │       ├── audit.py              GET /audit/logs
│   │       ├── sync.py               POST /sync/push, GET /sync/pull
│   │       └── health.py             GET /health, GET /ready
│   │
│   ├── blockchain/
│   │   ├── fabric_client.py          gRPC client — NIC MeghRaj Cloud
│   │   ├── evidence_chain.py         SHA-256 payload hash + Fabric commit
│   │   └── verifier.py               Evidence integrity verification
│   │
│   ├── core/
│   │   ├── security.py               OAuth2 JWT, Argon2/BCrypt
│   │   ├── rbac.py                   Role-Based Access Control
│   │   ├── rate_limiter.py           SlowAPI per-endpoint throttling
│   │   ├── pg_cache.py               PostgreSQL-native TTL key-value cache
│   │   ├── pg_queue.py               PostgreSQL-native task queue (SKIP LOCKED)
│   │   ├── middleware.py             Request logging + error handling
│   │   ├── exceptions.py             Custom exception hierarchy
│   │   └── responses.py              Standardized response wrappers
│   │
│   ├── db/
│   │   ├── postgres.py               SQLAlchemy async engine + session factory
│   │   └── mongodb.py                Motor async MongoDB client
│   │
│   ├── integrations/
│   │   ├── openfoodfacts_client.py   Open Food Facts barcode lookup
│   │   ├── whatsapp_client.py        WhatsApp Business API messaging
│   │   └── gs1_client.py             GS1 lookup interface
│   │
│   ├── models/                       SQLAlchemy ORM (7 tables)
│   │   ├── user.py                   User + role + hashed password
│   │   ├── inspection.py             Inspection + GPS + image path
│   │   ├── evidence.py               Blockchain evidence + SHA-256 hash
│   │   ├── gs1_product.py            Cached Open Food Facts data
│   │   ├── audit_log.py              System audit trail
│   │   ├── cache_entry.py            PG cache table (TTL key-value)
│   │   └── task_queue.py             PG task queue (job lifecycle)
│   │
│   ├── repositories/                 Data Access Layer
│   │   ├── inspection_repo.py
│   │   ├── evidence_repo.py
│   │   ├── gs1_repo.py
│   │   └── user_repo.py
│   │
│   ├── rules/                        Legal Metrology Compliance Engine
│   │   ├── engine.py                 Rule orchestrator (runs all rules)
│   │   ├── base.py                   Abstract base rule class
│   │   ├── mrp_rule.py               MRP declaration validation
│   │   ├── date_rule.py              Mfg + Expiry date validation
│   │   ├── net_quantity_rule.py      Net quantity validation
│   │   ├── font_size_rule.py         Font size & readability
│   │   ├── manufacturer_rule.py      Manufacturer details
│   │   ├── consumer_care_rule.py     Consumer care contact
│   │   ├── openfoodfacts_rule.py     OFF registry cross-reference
│   │   └── legal_metrology_rules.json  Machine-readable rules DB
│   │
│   ├── schemas/                      Pydantic request/response schemas
│   ├── security/                     Password hashing, JWT, AES-256
│   ├── services/                     Business logic (11 services)
│   └── storage/                      MinIO + local filesystem adapters
│
├── tests/                            37 Unit & Integration Tests
│   ├── conftest.py                   Fixtures: async DB session, auth headers
│   ├── test_auth.py                  JWT + login + registration (5 tests)
│   ├── test_rules.py                 Rule validations (10 tests)
│   ├── test_compliance.py            Rule engine evaluation (3 tests)
│   ├── test_ocr.py                   OCR engine (4 tests)
│   ├── test_gs1.py                   Open Food Facts lookup (4 tests)
│   ├── test_pg_cache_queue.py        PG cache + queue (4 tests)
│   ├── test_security.py              File validation + MIME (3 tests)
│   ├── test_evidence.py              SHA-256 + evidence (2 tests)
│   └── test_citizen.py              Complaints + WhatsApp (2 tests)
│
├── requirements.txt                  93 Python packages
└── .env.example                      50+ environment variables
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Required |
|------------|---------|----------|
| Python | 3.11+ | ✅ |
| PostgreSQL | 15+ | ✅ |
| MongoDB | 6+ | ✅ |
| MinIO | Latest | Optional |
| Google Cloud Vision Key | — | Optional (live OCR) |

### Installation

```bash
# 1. Go to backend directory
cd backend

# 2. Create virtual environment
python -m venv venv

# Windows:
venv\Scripts\activate
# Linux / macOS:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
# ⚠️ Edit .env — set DATABASE_URL, JWT_SECRET_KEY, ENCRYPTION_KEY
```

### Database Setup

```bash
# Create PostgreSQL database
psql -U postgres -c "CREATE USER parakh_user WITH PASSWORD 'your_password';"
psql -U postgres -c "CREATE DATABASE parakh_db OWNER parakh_user;"

# Run migrations
alembic upgrade head
```

### Start Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**API available at:**

| URL | Description |
|-----|-------------|
| `http://localhost:8000/docs` | Swagger UI (interactive) |
| `http://localhost:8000/redoc` | ReDoc documentation |
| `http://localhost:8000/api/v1/health` | Liveness probe |
| `http://localhost:8000/api/v1/ready` | Readiness probe |

### Run Tests

```bash
python -m pytest                                   # Run all 37 tests
python -m pytest -v                                # Verbose output
python -m pytest --cov=app --cov-report=term-missing  # With coverage
```

---

## 🧠 AI Pipeline

The pipeline runs on every scanned image through 6 stages:

```
Stage 1 — image_processor.py (OpenCV)
─────────────────────────────────────
  • Fast Non-Local Means Denoising
  • CLAHE Contrast Enhancement
  • Canny Edge Detection + ROI Crop
  • Hough Line Curved Surface Detection
  • Perspective Transform 3D Unwarping

Stage 2 — ocr_engine.py (Google Cloud Vision)
──────────────────────────────────────────────
  • Full raw text extraction
  • Per-word confidence scores
  • Bounding box vertices
  • Language detection

Stage 3 — nlp_extractor.py (BERT dslim/bert-base-NER)
───────────────────────────────────────────────────────
  • MRP             • Net Quantity
  • Mfg Date        • Expiry Date
  • Manufacturer    • Consumer Care Contact
  • Address         • Country of Origin

Stage 4 — rules/engine.py (8-Rule Compliance Engine)
─────────────────────────────────────────────────────
  • mrp_rule.py              MRP declared, format correct
  • date_rule.py             Mfg + Expiry dates valid
  • net_quantity_rule.py     Quantity in standard units
  • font_size_rule.py        Minimum font size per package area
  • manufacturer_rule.py     Name, address, FSSAI license
  • consumer_care_rule.py    Phone / email / address present
  • openfoodfacts_rule.py    Barcode matches OFF registry
  • gs1_rule.py              GS1 checksum + manufacturer match

Stage 5 — anomaly_detector.py (ViT google/vit-base-patch16-224)
────────────────────────────────────────────────────────────────
  • HSV Color Consistency Analysis
  • MSER Typography Check
  • Laplacian Logo Quality Check
  • ViT Feature Embedding Entropy

Stage 6 — evidence_chain.py (Blockchain)
─────────────────────────────────────────
  SHA-256 ( image_bytes + GPS + timestamp + OCR_text + violations )
      → PostgreSQL (evidence table)
      → MongoDB   (ai_extraction_logs)
      → Hyperledger Fabric (NIC MeghRaj)
```

---

## 📊 Database Schema

### PostgreSQL Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `users` | Accounts + roles | `id`, `email`, `role`, `hashed_password` |
| `inspections` | Inspection records | `id`, `inspector_id`, `latitude`, `longitude`, `status` |
| `evidence` | Blockchain evidence | `id`, `sha256_hash`, `blockchain_tx_id`, `violation_data` |
| `openfoodfacts_products` | Cached barcode lookups | `gtin`, `product_name`, `manufacturer`, `cached_at` |
| `audit_logs` | System audit trail | `id`, `actor_id`, `action`, `resource_type`, `created_at` |
| `cache_entries` | PG-native TTL cache | `key`, `value`, `expires_at` |
| `task_queue` | PG-native job queue | `id`, `task_type`, `status`, `payload` |

### MongoDB Collections

| Collection | Purpose |
|-----------|---------|
| `ai_extraction_logs` | Raw OCR text, NLP entities, bounding boxes, ViT findings |

---

## ⚙️ Environment Variables

Full template: [`.env.example`](.env.example) — 50+ configurable variables.

### Core Application
| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | `development` | `development` / `staging` / `production` |
| `DEBUG` | `true` | Enable debug mode |
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `8000` | Server port |
| `WORKERS` | `4` | Uvicorn worker count |

### Databases
| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql+asyncpg://...` | PostgreSQL async |
| `DATABASE_URL_SYNC` | `postgresql://...` | PostgreSQL sync (Alembic) |
| `DB_POOL_SIZE` | `20` | Connection pool size |
| `MONGODB_URL` | `mongodb://localhost:27017` | MongoDB |
| `MONGODB_DATABASE` | `parakh_db` | MongoDB database name |

### Authentication & Security
| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET_KEY` | ⚠️ **MUST SET** | JWT signing secret (64+ chars) |
| `JWT_ALGORITHM` | HS256 | JWT algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | 30 | Access token TTL |
| `ENCRYPTION_KEY` | ⚠️ **MUST SET** | AES-256 key (32-byte base64) |

```bash
# Generate secure JWT secret:
python -c "import secrets; print(secrets.token_urlsafe(64))"
```

### AI / ML
| Variable | Default | Description |
|----------|---------|-------------|
| `GOOGLE_CLOUD_VISION_KEY` | — | Cloud Vision API key |
| `NER_MODEL_NAME` | `dslim/bert-base-NER` | HuggingFace NER model |
| `VIT_MODEL_NAME` | `google/vit-base-patch16-224` | ViT anomaly model |
| `NER_CONFIDENCE_THRESHOLD` | `0.5` | Minimum NER confidence |
| `ANOMALY_DETECTION_ENABLED` | `true` | Enable ViT detection |

### Storage
| Variable | Default | Description |
|----------|---------|-------------|
| `STORAGE_PROVIDER` | `minio` | `minio` or `local` |
| `MINIO_ENDPOINT_URL` | `http://localhost:9000` | MinIO server |
| `LOCAL_STORAGE_PATH` | — | Local path (if `STORAGE_PROVIDER=local`) |

### Rate Limiting
| Variable | Default |
|----------|---------|
| `RATE_LIMIT_LOGIN` | `5/minute` |
| `RATE_LIMIT_UPLOAD` | `20/minute` |
| `RATE_LIMIT_ANALYSIS` | `10/minute` |
| `RATE_LIMIT_DEFAULT` | `60/minute` |

---

## 🔌 API Reference

All endpoints prefixed with `/api/v1`. Interactive docs: `http://localhost:8000/docs`.

### Quick Examples

```bash
# Register a user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "inspector@parakh.gov.in", "password": "SecurePass123!", "role": "inspector"}'

# Login (get JWT token)
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "inspector@parakh.gov.in", "password": "SecurePass123!"}'

# Upload product image (returns inspection_id)
curl -X POST http://localhost:8000/api/v1/scan/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@product_label.jpg" \
  -F "latitude=28.6139" \
  -F "longitude=77.2090"

# Run full AI compliance check
curl -X POST http://localhost:8000/api/v1/analysis/<inspection_id>/verify \
  -H "Authorization: Bearer <token>" \
  -d '{"product_barcode": "8901234567890"}'

# Commit evidence to blockchain
curl -X POST http://localhost:8000/api/v1/evidence/commit \
  -H "Authorization: Bearer <token>" \
  -d '{"inspection_id": "<uuid>", "violation_data": {...}}'
```

### All Endpoints

| Module | Method | Endpoint | Auth |
|--------|:------:|----------|:----:|
| Health | GET | `/health` | — |
| Health | GET | `/ready` | — |
| Auth | POST | `/auth/login` | — |
| Auth | POST | `/auth/register` | — |
| Users | GET | `/users/me` | JWT |
| Users | PUT | `/users/{id}` | JWT |
| Scan | POST | `/scan/upload` | JWT |
| Scan | POST | `/scan/process` | JWT |
| Scan | GET | `/scan/barcode/{gtin}` | — |
| Analysis | POST | `/analysis/{id}/verify` | JWT |
| Compliance | GET | `/compliance/{id}` | JWT |
| Inspections | GET | `/inspections` | JWT |
| Inspections | POST | `/inspections` | JWT |
| Inspections | GET | `/inspections/{id}/export/pdf` | JWT |
| Inspections | GET | `/inspections/{id}/export/json` | JWT |
| Inspections | GET | `/inspections/{id}/export/csv` | JWT |
| Evidence | POST | `/evidence/commit` | JWT |
| Evidence | GET | `/evidence/verify` | JWT |
| Citizen | POST | `/citizen/report` | JWT |
| Citizen | POST | `/citizen/whatsapp` | — |
| Analytics | GET | `/analytics/summary` | JWT |
| Heatmaps | GET | `/heatmaps` | JWT |
| Legal | POST | `/legal-notices/generate` | JWT |
| Audit | GET | `/audit/logs` | JWT |
| Sync | POST | `/sync/push` | JWT |
| Sync | GET | `/sync/pull` | JWT |

---

## 🧪 Test Coverage

| Test File | Tests | Covers |
|-----------|------:|--------|
| `test_auth.py` | 5 | JWT login, registration, token refresh, password hashing |
| `test_rules.py` | 10 | MRP, date, quantity, font, manufacturer, consumer care rules |
| `test_compliance.py` | 3 | Rule engine overall status evaluation |
| `test_ocr.py` | 4 | OCR initialization and text extraction |
| `test_gs1.py` | 4 | Open Food Facts barcode lookup + caching |
| `test_pg_cache_queue.py` | 4 | PG cache CRUD/expiry + task queue lifecycle |
| `test_security.py` | 3 | File validation, MIME check, script rejection |
| `test_evidence.py` | 2 | SHA-256 hash computation + evidence packaging |
| `test_citizen.py` | 2 | Complaint submission + WhatsApp webhook |
| **Total** | **37** | **All passing ✅** |

---

## 🚢 Deployment

### Docker

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```bash
docker build -t parakh-backend .
docker run -d --name parakh-api -p 8000:8000 --env-file .env parakh-backend
```

### Production Checklist

- [ ] `APP_ENV=production`, `DEBUG=false`
- [ ] Rotate `JWT_SECRET_KEY` and `ENCRYPTION_KEY`
- [ ] PostgreSQL with SSL + PgBouncer
- [ ] `BLOCKCHAIN_ENABLED=true` with NIC credentials
- [ ] HTTPS reverse proxy (Nginx / Traefik)
- [ ] Swagger disabled: `docs_url=None` in production config
- [ ] `AUDIT_LOG_ENABLED=true`

---

## 🛠️ Development Commands

```bash
# Format code
black app/ tests/

# Lint
ruff check app/ tests/

# Type check
mypy app/

# Create migration
alembic revision --autogenerate -m "add_new_column"
alembic upgrade head
```

---

> **🖥️ PARAKH Backend** — *AI-powered compliance at scale*
>
> Part of [Project PARAKH](../README.md) — Government of India
