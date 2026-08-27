# Project PARAKH — Technology Stack

**Problem Statement ID:** 26034
**Organization:** Ministry of Consumer Affairs, Food & Public Distribution (DoCA)
**Theme:** Agriculture, FoodTech & Rural Development
**Project Team:** Nikhil Pandey, Tanushree, Sudha, Akshay Paswan, Jitendra Choudhary, Aaryan Kasaudhan

---

## 1. Mobile / Edge Client

| Component | Technology |
|---|---|
| Cross-platform app framework | **Flutter** |
| Augmented Reality engine | **ARCore** (Android) & **ARKit** (iOS) — native AR plugins invoked through Flutter for live overlay scanning and red/green bounding-box projection |
| Offline support | Local on-device storage with background sync once connectivity is restored |
| Barcode scanning | Native barcode/QR reader for GS1 EAN/UPC lookup |

## 2. Web Dashboard (DoCA Command Center)

| Component | Technology |
|---|---|
| Framework | **Next.js** |
| Styling | **Tailwind CSS** |
| Key modules | Inspection history & search, predictive heatmaps, citizen-report triage console, evidentiary ledger viewer |

## 3. Backend / Application Server

| Component | Technology |
|---|---|
| API framework | **Python (FastAPI)** — async, high-performance AI routing |
| Architecture style | RESTful services (`/api/v1/...`) |
| Access control | Role-Based Access Control (RBAC) for Inspector / Admin / Citizen roles |
| Security | TLS encryption in transit, AES-256 encryption at rest |

## 4. AI / ML Pipeline

| Capability | Technology |
|---|---|
| Optical Character Recognition (OCR) | **Google Cloud Vision API** |
| Natural Language Processing (entity parsing — MRP, dates, consumer care) | **HuggingFace Transformers** |
| Computer Vision — 3D surface unwarping & bounding boxes | **OpenCV** |
| Counterfeit / anomaly detection | **HuggingFace Vision Transformers (ViT)** — logo, typography & color-gradient anomaly detection |
| Predictive analytics | Scikit-learn / gradient-boosted models for geo-spatial & seasonal risk heatmaps |

## 5. Data Layer

| Store | Purpose | Key Entities |
|---|---|---|
| **PostgreSQL** (Relational) | Users, inspections, GS1 product registry | `users`, `inspections`, `gs1_products` |
| **MongoDB** (Unstructured) | AI metadata & logs | `ai_extraction_logs` (raw OCR text, parsed entities, rule-engine pass/fail flags) |

## 6. Blockchain — Evidentiary Ledger

| Component | Technology |
|---|---|
| Ledger platform | **Hyperledger Fabric** (permissioned blockchain) |
| Hosting infrastructure | **NIC MeghRaj** (Government of India's national cloud) — keeps evidentiary data within sovereign infrastructure |
| Hashing | SHA-256 hash of image + timestamp + GPS + extracted text, committed on violation detection |
| Purpose | Tamper-proof, legally admissible evidence trail |

## 7. External Integrations

| Integration | Purpose |
|---|---|
| **GS1 India API** | Cross-reference scanned barcode against registered manufacturer to catch "ghost" manufacturers |
| **WhatsApp Business API** | Citizen "Lite" reporting bot for public crowdsourced complaints |

## 8. Core API Endpoints

- `POST /api/v1/scan/upload` — upload encrypted field images to cloud storage
- `POST /api/v1/analysis/verify-compliance` — trigger AI pipeline (Unwarping → OCR → NLP) + Rule Engine
- `POST /api/v1/evidence/commit` — write hashed violation evidence to Hyperledger
- `GET /api/v1/dashboard/heatmaps` — fetch aggregated geo-spatial data for the dashboard

## 9. Non-Functional / Infrastructure Considerations

- **Performance:** capture-to-verdict latency ≤ 5 seconds under standard network conditions
- **Scalability:** must support concurrent nationwide usage by thousands of officials
- **Security:** end-to-end encryption + strict RBAC
- **Usability:** mobile UI operable by a non-technical field officer with < 30 minutes training
- **Platform independence:** mobile app across major OS versions; dashboard across modern browsers

---

### Summary Stack at a Glance

```
Mobile/Edge    : Flutter + ARCore/ARKit
Web Dashboard  : Next.js + Tailwind CSS
Backend        : Python (FastAPI)
OCR            : Google Cloud Vision API
NLP            : HuggingFace Transformers
Computer Vision: OpenCV + HuggingFace ViT
Databases      : PostgreSQL + MongoDB
Blockchain     : Hyperledger Fabric on NIC MeghRaj (Govt. of India Cloud)
Integrations   : GS1 India API, WhatsApp Business API
```
