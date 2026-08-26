# Project PARAKH — REST API Reference Guide

This document defines the REST API contract exposed by the PARAKH FastAPI backend for frontend integration (Flutter Mobile App & Next.js Admin Dashboard).

---

## 1. Response Standard

All endpoints return JSON wrapped in the unified response envelope:

### Success (HTTP 200/201)
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation description",
  "error": null
}
```

### Error (HTTP 4xx / 5xx)
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Human-readable explanation",
    "details": {}
  }
}
```

---

## 2. Authentication & Authorization

All protected endpoints require an `Authorization: Bearer <access_token>` header.

### Endpoints
* **`POST /api/v1/auth/login`**
  * Body: `{"email": "user@parakh.gov.in", "password": "..."}`
  * Response: Returns `access_token`, `refresh_token`, and user profile.
* **`POST /api/v1/auth/refresh`**
  * Body: `{"refresh_token": "..."}`
* **`POST /api/v1/auth/logout`**

---

## 3. Enforcement & AI Vision

* **`POST /api/v1/scan/upload`**
  * `multipart/form-data`: `file` (image), `product_barcode`, `latitude`, `longitude`, `location_name`.
  * Roles: `inspector`, `admin`
* **`POST /api/v1/analysis/verify-compliance`**
  * Body: `{"inspection_id": "uuid", "product_barcode": "890..."}`
  * Triggers: OpenCV 3D Unwarping → Google Cloud Vision OCR → HuggingFace NER → GS1 Cross-Check → Rule Engine.
  * Roles: `inspector`, `admin`
  * Response: Extracted entities, Pass/Fail breakdown per rule, and overall status (`COMPLIANT`, `VIOLATION`, `REQUIRES_REVIEW`, `INSUFFICIENT_DATA`).

---

## 4. Blockchain & Evidentiary Ledger

* **`POST /api/v1/evidence/commit`**
  * Body: `{"inspection_id": "uuid", "violation_data": { ... }}`
  * Computes SHA-256 hash and anchors to Hyperledger Fabric.
* **`POST /api/v1/evidence/{id}/verify`**
  * Recomputes SHA-256 and validates against ledger receipt. Returns `VERIFIED` or `MISMATCH`.

---

## 5. Command Center & Geospatial Heatmaps

* **`GET /api/v1/analytics/dashboard`** — Total inspections, violation rates, citizen complaints.
* **`GET /api/v1/dashboard/heatmaps`** — Actual coordinates of infractions and ML predicted risk clusters.
* **`POST /api/v1/legal-notices/generate`** — Builds statutory PDF notice with cryptographic seal.
* **`GET /api/v1/legal-notices/{id}/download`** — Downloads formal PDF.

---

## 6. Citizen Crowdsourcing

* **`POST /api/v1/citizen/reports`** — Uploads suspect packaging photograph; triggers automated AI quality triage.
* **`GET /api/v1/citizen/reports/{id}/status`** — Citizen tracks review outcome.
* **`PUT /api/v1/citizen/reports/{id}/triage`** — Admin approves/rejects complaint.
