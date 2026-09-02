# **Project PARAKH: Advanced Legal Metrology Compliance System**

**Problem Statement ID:** 26034
**Organization:** Ministry of Consumer Affairs, Food & Public Distribution (DoCA)
**Theme:** Agriculture, FoodTech & Rural Development
**Project Team:** Nikhil Pandey, Tanushree, Sudha, Akshay Paswan, Jitendra Choudhary, Aaryan Kasaudhan

*Project PARAKH* (meaning "to examine or assess" in Hindi) is a next-generation, AI-driven and Blockchain-secured software system designed to automate the compliance checking of packaged commodities under the Legal Metrology (Packaged Commodities) Rules, 2011 [cite: 1.1.1, 1.1.2].

---

## **1. Executive Summary & Core Concept**
The Legal Metrology Rules, 2011 mandate strict declarations on pre-packaged goods, including the Manufacturer's Name and Address, Net Quantity, MRP (inclusive of all taxes), Month and Year of Manufacture, and Consumer Care details [cite: 1.1.1, 1.1.4]. Currently, enforcing these rules is manual and time-consuming. 

**Project PARAKH** replaces manual checks with:
1. **AR-Powered Scanning:** Live Augmented Reality overlays to scan store shelves in real-time.
2. **AI-Vision Engine:** 3D unwarping and Optical Character Recognition (OCR) to read text on curved/crumpled surfaces.
3. **Automated Rule Engine:** Instantly cross-referencing extracted text with legal thresholds.
4. **Blockchain Evidentiary Ledger:** Cryptographically securing non-compliance records to ensure legally admissible evidence.

---

## **2. System Architecture Blueprint**

### **2.1. Technology Stack**
*   **Mobile / Edge Client:** Flutter (iOS & Android) with ARCore/ARKit integration.
*   **Web Dashboard:** Next.js with Tailwind CSS for DoCA officials.
*   **Backend Server:** Python (FastAPI) for high-performance AI routing and asynchronous processing.
*   **AI/ML Pipeline:** 
    *   *OCR:* Google Cloud Vision API.
    *   *NLP & NER:* HuggingFace Transformers (`dslim/bert-base-NER`).
    *   *Computer Vision & Anomaly Detection:* OpenCV (Image unwarping) & HuggingFace ViT (`google/vit-base-patch16-224`).
*   **Databases:** PostgreSQL (Relational Data, Key-Value Cache & Task Queue) & MongoDB (Unstructured Logs).
*   **Blockchain Ledger:** Hyperledger Fabric (for immutable evidence trails).

### **2.2. Database Schema Design**

**Unified Sovereign Database (PostgreSQL)** - *Manages access, users, core ledger, cache, and background queue.*
*   **`users`**: `user_id` (UUID), `full_name`, `role` (Inspector/Admin/Citizen), `zone_id`.
*   **`inspections`**: `inspection_id` (UUID), `timestamp`, `geo_location` (Lat/Long), `status` (Compliant/Violation), `blockchain_hash`.
*   **`openfoodfacts_products`**: `barcode_upc`, `registered_manufacturer`, `product_category`.
*   **`cache_entries`**: `key`, `value`, `counter`, `expires_at`, `created_at`, `updated_at`.
*   **`task_queue`**: `task_id`, `task_type`, `status`, `payload`, `result`, `priority`, `scheduled_at`.

**Unstructured Logs (MongoDB)** - *Stores AI metadata.*
*   **`ai_extraction_logs`**:
    *   `inspection_id`
    *   `raw_ocr_text`
    *   `parsed_entities` (e.g., MRP value, Confidence Score, Bounding Box coordinates).
    *   `rule_engine_results` (Pass/Fail flags for specific Legal Metrology rules).

---

## **3. End-to-End Workflow**

**Phase 1: Input & Data Capture (Edge)**
1.  An Enforcement Official or Citizen opens the *PARAKH App*.
2.  The camera scans the physical product using **AR Overlays**. The app captures multiple angles.
3.  The app automatically scans the barcode to fetch registered product details from Open Food Facts for cross-referencing.

**Phase 2: AI Processing (Vision Engine)**
4.  **3D Unwarping:** Curved packages (bottles/cans) are digitally flattened.
5.  **Text Extraction & Parsing:** OCR reads the label, and NLP extracts entities (e.g., categorizing "₹ 50" as MRP and "abc@brand.com" as Consumer Care).

**Phase 3: The Rule Engine (Validation)**
6.  The extracted data is run through the PARAKH Rule Engine.
    *   *Rule 1:* Is MRP present and correctly formatted? [cite: 1.1.1]
    *   *Rule 2:* Are manufacturing and expiry dates readable? [cite: 1.1.1]
    *   *Rule 3:* Are Consumer Care details (Address/Email) complete? [cite: 1.1.1]
    *   *Rule 4:* Does the extracted manufacturer match the barcode owner?

**Phase 4: Verdict & Securitization**
7.  **If Compliant:** The app flashes green, and a standard log is sent to the database.
8.  **If Violation Detected:** The app flags the missing/incorrect data. 
    *   The image, timestamp, GPS location, and violation details are hashed using SHA-256.
    *   The hash is committed to the **Blockchain Ledger** to prevent tampering of evidence.

**Phase 5: Reporting & Action**
9.  A PDF Legal Notice is auto-generated, embedding the bounding-box photos and the cryptographic receipt.
10. The DoCA Admin Dashboard updates its predictive heatmaps, alerting officials to regional compliance trends.

---

## **4. Core API Endpoints (RESTful)**

*   **`POST /api/v1/scan/upload`**
    *   *Function:* Uploads encrypted product images from the field app to cloud storage.
*   **`POST /api/v1/analysis/verify-compliance`**
    *   *Function:* Triggers the AI pipeline (Unwarping -> OCR -> NLP) and runs the Rule Engine. Returns compliance status and bounding boxes.
*   **`POST /api/v1/evidence/commit`**
    *   *Function:* Writes the hashed violation evidence to the Hyperledger blockchain.
*   **`GET /api/v1/dashboard/heatmaps`**
    *   *Function:* Fetches aggregated geo-spatial data for the DoCA command center dashboard.
