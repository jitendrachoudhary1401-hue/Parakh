# Project PARAKH — AI & Computer Vision Architecture Audit

---

## 1. Executive Summary

Project PARAKH leverages a multi-stage **Artificial Intelligence, Computer Vision, and Natural Language Processing (NLP)** pipeline specifically engineered for automated Legal Metrology enforcement under the Ministry of Consumer Affairs, Food & Public Distribution (DoCA). 

The AI stack processes mobile package scans, unwarps curved bottle/can surfaces, extracts printed declarations, evaluates mandatory compliance rules, detects visual anomalies/counterfeits, generates cryptographic evidence hashes, and predicts high-risk enforcement zones.

---

## 2. Detailed AI Engine Implementations

### 2.1 Google Cloud Vision OCR Engine
* **File Location:** `backend/app/ai/ocr_engine.py`
* **Core Technology:** Google Cloud Vision API (`google-cloud-vision` Python SDK)
* **Capabilities:**
  * Extracts raw text from complex Indian packaging labels.
  * Calculates word-level confidence scores and exact polygon vertex bounding boxes.
  * Detects language automatically (English, Hindi, regional Indian languages).
* **Authentication Fallback Hierarchy:**
  1. Inline `GOOGLE_CLOUD_VISION_CREDENTIALS_JSON` environment string.
  2. Service Account JSON file path (`GOOGLE_APPLICATION_CREDENTIALS`).
  3. Vision API Key (`GOOGLE_CLOUD_VISION_KEY`).
  4. Google Application Default Credentials (ADC).

---

### 2.2 OpenCV Image Preprocessing & 3D Surface Unwarping
* **File Location:** `backend/app/ai/image_processor.py`
* **Core Technology:** OpenCV 4.x (`cv2`) & NumPy
* **Capabilities:**
  * **Noise Reduction & Contrast:** Fast Non-Local Means Denoising + CLAHE (Contrast Limited Adaptive Histogram Equalization).
  * **Product Boundary Detection:** Canny edge detection and largest contour ROI cropping.
  * **Curved Surface Detection:** Hough line transform angle-variance analysis for cylindrical bottles, cans, and flexible pouches.
  * **Perspective Correction:** 3D perspective transform matrix to flatten curved labels prior to OCR text extraction.
  * **Quality Assessment:** Laplacian variance sharpness and contrast scoring (rejects low-quality images below the 0.3 score threshold).

---

### 2.3 HuggingFace Transformers NLP Engine
* **File Location:** `backend/app/ai/nlp_extractor.py`
* **Core Technology:** HuggingFace `transformers` pipeline (`dslim/bert-base-NER`) + Legal Metrology Regex
* **Capabilities:**
  * Extracts structured entity key-value pairs from raw OCR text.
  * Extracted Legal Metrology Declarations:
    * `MRP` (Maximum Retail Price including taxes)
    * `NET_QUANTITY` (Weight / Volume / Count e.g. `500g`, `1L`, `10 pcs`)
    * `MFG_DATE` / `PKG_DATE` (Date of Manufacture / Packing)
    * `EXPIRY_DATE` / `BEST_BEFORE` (Expiry date or shelf life duration)
    * `CONSUMER_CARE` (Helpline phone, email, toll-free number, consumer care address)
    * `MANUFACTURER_NAME` and `MANUFACTURER_ADDRESS`
  * **Strict Error Handling:** No mock fallback or silent suppression. If model loading or inference fails, an explicit failure is returned.

---

### 2.4 HuggingFace ViT Anomaly & Anti-Counterfeit Detector
* **File Location:** `backend/app/ai/anomaly_detector.py`
* **Core Technology:** HuggingFace Vision Transformer (`google/vit-base-patch16-224`) + OpenCV Feature Analytics
* **Capabilities:**
  * **Color Variation:** HSV quadrant color distribution variance check to flag tampered overlay labels.
  * **Typography Check:** MSER (Maximally Stable Extremal Regions) text contour size distribution checking.
  * **Logo Integrity:** Laplacian top-region variance checking for blurred or low-quality logo prints.
  * **ViT Embedding Analysis:** Visual feature out-of-distribution detection to flag potential counterfeit packaging.
  * **Strict Error Handling:** Direct model execution without mock fallbacks; surfaces errors immediately if ViT fails.

---

### 2.5 AI Citizen Complaint Triage Engine
* **File Location:** `backend/app/ai/ai_triage.py`
* **Core Technology:** Computer Vision + Text Density Classifier
* **Capabilities:**
  * Filters public citizen-submitted reports before administrative review.
  * Classifications: `blurry`, `irrelevant`, `potential_violation`, `apparently_compliant`, `requires_review`.
  * Prevents spam and non-actionable reports from flooding officer queues.

---

### 2.6 Predictive Risk Analytics Engine
* **File Location:** `backend/app/ai/predictive.py`
* **Core Technology:** `scikit-learn` (`GradientBoostingClassifier` + `StandardScaler`)
* **Capabilities:**
  * Evaluates historical geotagged inspection data (latitude, longitude, month, day, product category).
  * Clusters high-risk enforcement geographic zones and generates predictive risk scores.
  * Gracefully returns `INSUFFICIENT_DATA` status when fewer than 30 historical records exist.

---

## 3. End-to-End Compliance Pipeline Execution Flow

```
Mobile Scan (Image + GPS)
       │
       ▼
OpenCV Preprocessing & 3D Unwarping (app/ai/image_processor.py)
       │
       ▼
Google Cloud Vision OCR (app/ai/ocr_engine.py)
       │
       ▼
HuggingFace NLP Entity Extraction (app/ai/nlp_extractor.py)
       │
       ▼
Open Food Facts Barcode Cross-Check (app/integrations/openfoodfacts_client.py)
       │
       ▼
Legal Metrology Rule Engine Evaluation (app/rules/engine.py)
       │
       ▼
ViT Anomaly & Counterfeit Scoring (app/ai/anomaly_detector.py)
       │
       ▼
Violation Detected?
 ├── YES ──► Generate Cryptographic SHA-256 Hash (Image + GPS + Timestamp + OCR)
 │           Commit to Hyperledger Fabric Ledger & MongoDB ai_extraction_logs
 └── NO  ──► Save Compliant Record to PostgreSQL Inspection Store
```

---

## 4. Cryptographic Violation Hash Generation

When an AI compliance scan yields `overall_status == "VIOLATION"`, `AnalysisService` computes a deterministic SHA-256 evidence hash combining:

```python
SHA256("IMAGE:" + image_path + "|GPS:" + lat + "," + lon + "|TIME:" + timestamp + "|INSPECTOR:" + inspector_id + "|OCR:" + ocr_text + "|VIOLATIONS:" + violation_json)
```

This hash is stored in PostgreSQL (`Inspection.blockchain_hash`), archived in MongoDB (`ai_extraction_logs.evidence_hash`), and committed to Hyperledger Fabric for legal admissibility under Section 65B of the Indian Evidence Act.

---

## 5. Implementation Status Matrix

| Component | Code Status | Live Production Requirement |
|---|---|---|
| **Google Cloud Vision OCR** | **100% Implemented** | `GOOGLE_CLOUD_VISION_KEY` / Service Account JSON in `.env` |
| **OpenCV 3D Unwarping** | **100% Implemented** | Local OpenCV runtime (`cv2` & `numpy`) |
| **HuggingFace NLP (NER)** | **100% Implemented** | Local PyTorch runtime (`transformers` model download) |
| **HuggingFace ViT Anomaly** | **100% Implemented** | Fine-tuned weights on 10,000+ Indian packaging images |
| **AI Citizen Triage** | **100% Implemented** | Local OpenCV & regex classifier |
| **Predictive Risk Analytics** | **100% Implemented** | `scikit-learn` runtime + 30+ historical inspection records |
| **Hyperledger Blockchain** | **100% Implemented** | Live MSP Org Certificate on NIC MeghRaj Cloud |
