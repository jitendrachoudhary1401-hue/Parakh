# PROJECT PARAKH — AI Instructions & Master Status Report
**Advanced AI-Powered Legal Metrology Compliance System**

**Problem Statement ID:** 26034  
**Organization:** Ministry of Consumer Affairs, Food & Public Distribution (DoCA)  
**System Status:** 100% Complete & Production Ready (Full-Stack: FastAPI Gateway + Flutter Mobile Frontend)

---

## 1. Core Architectural Directives

1. **CLEAN SYSTEM SEPARATION & API INTEGRATION**: 
   - The backend provides clean, versioned REST APIs (`/api/v1/...`) consumed independently by the **Stitch-designed Flutter Mobile Frontend** (`mobile_app/`).
   - The frontend implements the **Stitch Institutional Minimalism** design system with vector SVG branding and strict offline-first resilience.
2. **ABSOLUTE NO-FAKE-DATA RULE**:
   - Zero mock/fake production data in schemas, services, or production models.
   - If external services or data are unavailable, structured status codes (`INSUFFICIENT_DATA`, `SERVICE_UNAVAILABLE`, `BLOCKCHAIN_SERVICE_UNAVAILABLE`, `OFFLINE_MODE`) are returned.
3. **STRICT SERVER-SIDE & CLIENT-SIDE RBAC**:
   - `inspector`: Real-time AR scanning, GS1 cross-referencing, compliance analysis, offline sync queue, evidence anchoring, and notice generation.
   - `admin`: Full oversight, audit logs, citizen triage, heatmaps, legal notice generation, blockchain audits, user management.
   - `citizen`: Submit packaging reports, track own submission status.
4. **POLYGLOT STORAGE & LEDGER**:
   - **PostgreSQL**: Relational entities (`users`, `inspections`, `gs1_products`, `citizen_reports`, `evidence`, `legal_notices`, `audit_logs`).
   - **MongoDB**: AI extraction logs, raw OCR outputs, bounding boxes, rule execution metadata (`ai_extraction_logs`).
   - **Object Storage**: MinIO (Self-Hosted S3-Compatible) & Local Encrypted Filesystem for raw images, unwarped images, and generated PDF legal notices.
   - **Hyperledger Fabric**: SHA-256 evidence anchoring for tamper-proof legal admissibility.
   - **Local Mobile Cache**: SQLite/SharedPreferences buffer for offline retail basement inspections.
5. **AI & COMPUTER VISION PIPELINE**:
   - **OpenCV**: Denoising, CLAHE, contour boundary detection, curvature detection, perspective 3D unwarping.
   - **Google Cloud Vision**: Multi-region OCR extraction with word-level bounding boxes and confidence.
   - **HuggingFace Transformers**: Named Entity Recognition (NER) for Legal Metrology fields (MRP, Net Qty, Dates, Consumer Care, Manufacturer).
   - **HuggingFace ViT**: Micro-anomaly analysis for packaging, logos, typography, and color gradients.
   - **Scikit-learn**: Geographic and seasonal violation predictive modeling.

---

## 2. Complete Deliverables & Status Matrix

| Module | Status | Path | Key Capabilities |
|---|---|---|---|
| **App Entry & Config** | ✅ 100% | `app/main.py`, `app/config.py` | FastAPI gateway, lifespan DB init, CORS, secure headers, SlowAPI rate limiting |
| **Database Connections** | ✅ 100% | `app/db/postgres.py`, `app/db/mongodb.py` | Async SQLAlchemy connection pooling + Motor async client |
| **PostgreSQL Models** | ✅ 100% | `app/models/*.py` | 7 tables (`users`, `inspections`, `gs1_products`, `citizen_reports`, `evidence`, `legal_notices`, `audit_logs`) |
| **Alembic Migrations** | ✅ 100% | `alembic/versions/001_initial_schema.py` | Initial migration for all tables, indexes, and constraints |
| **Security & RBAC** | ✅ 100% | `app/core/security.py`, `app/core/rbac.py` | OAuth2, JWT access/refresh, bcrypt, strict role dependency factories |
| **Standardized Responses** | ✅ 100% | `app/core/responses.py`, `app/core/exceptions.py` | Unified success/error envelope per §39; sanitizes internal stack traces |
| **Pydantic Schemas** | ✅ 100% | `app/schemas/*.py` | 12 modules covering all request/response validation contracts |
| **Repositories** | ✅ 100% | `app/repositories/*.py` | 8 async data access classes |
| **AI Vision & NLP** | ✅ 100% | `app/ai/*.py` | OpenCV unwarping, GCP Vision OCR, HuggingFace NER, ViT anomalies, Scikit-learn predictive model |
| **Rule Engine** | ✅ 100% | `app/rules/*.py` | 6 rules (MRP, Net Qty, Dates, Consumer Care, Manufacturer, GS1 Cross-check) + orchestrator |
| **Blockchain** | ✅ 100% | `app/blockchain/*.py` | Hyperledger Fabric client, SHA-256 evidence hasher, and verification engine |
| **Object Storage** | ✅ 100% | `app/storage/*.py` | S3, MinIO, and Azure Blob implementations with presigned URLs |
| **Integrations** | ✅ 100% | `app/integrations/*.py` | GS1 India API client and Meta WhatsApp Business API client |
| **Services** | ✅ 100% | `app/services/*.py` | 11 orchestration services for all business domain flows |
| **API Endpoints** | ✅ 100% | `app/api/v1/*.py` | Complete REST API (`/api/v1/auth`, `/scan`, `/analysis`, `/inspections`, `/evidence`, `/citizen`, `/dashboard/heatmaps`, `/legal-notices`, `/audit`, `/sync`, `/health`) |
| **Test Suites** | ✅ 100% | `tests/*.py` | 8 test suites covering auth, rules, OCR, GS1, blockchain, security, and triage |
| **Infrastructure** | ✅ 100% | `infrastructure/` | Multi-stage Dockerfile, docker-compose full stack, Kubernetes manifests (Deployment, Service, ConfigMap, Secrets, HPA, Ingress) |
| **Documentation** | ✅ 100% | `README.md`, `docs/api_guide.md` | System overview, quickstart instructions, and complete API reference |
| **Flutter Mobile App** | ✅ 100% | `mobile_app/` | Complete 11-screen Inspector application adhering strictly to Stitch Institutional Minimalism |

---

## 3. Flutter Mobile Frontend Architecture (`mobile_app/`)

### 3.1. Design System Tokens (Stitch Institutional Minimalism)
- **Primary Brand Color**: Deep Navy (`#031631` / `#1A2B47`)
- **Secondary Accent**: Slate Gray (`#505F76` / `#64748B`)
- **Functional Colors**: Emerald Green (`#00A673` / `#10B981` Pass), Crimson Alert (`#BA1A1A` Violation), Amber Warning (`#D97706` Offline)
- **Surfaces & Borders**: Neutral Slate (`#F7F9FB`), 1px Slate-200 (`#E2E8F0`) boundary outlines, 4px structured radius (`rounded-sm`).
- **Typography**: Google Font **Work Sans** (high legibility, wide apertures for numbers and metrology data).
- **Official Branding**: Vector SVG logo asset (`assets/logo.svg`) from official Ministry & Project PARAKH specifications.

### 3.2. Mobile Workflow Screens Matrix

1. **Splash Screen** (`lib/screens/splash_screen.dart`): Animated SVG logo with Ministry & Problem Statement ID 26034 branding.
2. **Login & Biometrics** (`lib/screens/login_screen.dart`): Official ID, password, 2FA OTP, and instant fingerprint/FaceID field unlock.
3. **Inspector Dashboard** (`lib/screens/dashboard_screen.dart`): Daily progress metrics (Compliant vs Violations), quick action tiles, recent inspection ledger, and bottom navigation.
4. **AR Live Camera Viewfinder** (`lib/screens/ar_camera_screen.dart`): Real-time packaging HUD with Green/Red AR bounding box overlays, OCR confidence tag, flashlight, auto-focus, and shutter.
5. **GS1 Barcode Scanner** (`lib/screens/barcode_scanner_screen.dart`): GTIN barcode reader with live lookup against registered manufacturer database.
6. **AI Extraction Review** (`lib/screens/ai_review_screen.dart`): 3D surface unwarped image sanity check + structured extracted declarations (MRP, Net Qty, Dates, Consumer Care, Manufacturer).
7. **Compliance Verdict Screen** (`lib/screens/compliance_verdict_screen.dart`): Pass/Violation banner with rule-by-rule Legal Metrology 2011 assessment.
8. **Evidence & Legal Notice Generator** (`lib/screens/evidence_report_screen.dart`): Immutable SHA-256 blockchain receipt preview and in-app legal notice PDF generator.
9. **Inspection History Ledger** (`lib/screens/inspection_history_screen.dart`): Searchable and filterable ledger by date, status, and violation category.
10. **Offline Sync Hub** (`lib/screens/offline_sync_hub_screen.dart`): Offline inspection queue manager with auto-retry and retail basement simulation.
11. **Profile & Settings** (`lib/screens/profile_settings_screen.dart`): Official credentials, assigned jurisdiction zone, English/Hindi localization, and gateway config.

---

## 4. Instructions
**no mock data should be generated** and **every function should be run**