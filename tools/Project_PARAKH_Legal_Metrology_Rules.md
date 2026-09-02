# Project PARAKH — Legal Metrology Statutory Rule Engine & Codified Clauses
**Document Identifier:** DOCA-PARAKH-LEGAL-RULES-2026  
**Source Statute:** The Legal Metrology Act, 2009 (Act No. 1 of 2010) & The Legal Metrology (Packaged Commodities) Rules, 2011  
**Source Document:** `8_1732871406.pdf` (DoCA Official Gazette G.S.R. 202(E) as amended)  
**SHA-256 Checksum:** `48cd6acdb5475709631b741d71b2948d45713e7e8758ce531c19948a7e31f890`  

---

## 1. Statutory Document Registry Schema (`legal_documents` Table)

To guarantee legal admissibility and an immutable audit trail, every compliance check is cryptographically anchored to the exact statutory document version active on the date of inspection:

| Column Name | Data Type | Constraint | Description |
|---|---|---|---|
| `law_id` | `UUID` | `PRIMARY KEY` | Unique identifier for the statutory document record |
| `title` | `VARCHAR(255)` | `NOT NULL` | Statutory title (*e.g., "The Legal Metrology (Packaged Commodities) Rules, 2011"*) |
| `version_hash` | `VARCHAR(64)` | `NOT NULL` | Cryptographic SHA-256 hash of the official DoCA PDF document (`8_1732871406.pdf`) |
| `effective_date` | `DATE` | `NOT NULL` | Official date when the statutory rules / amendment came into force (`2011-04-01`) |
| `document_url` | `VARCHAR(500)` | `NOT NULL` | Direct URI to official Ministry gazette repository |
| `gazette_notification` | `VARCHAR(255)` | `NULLABLE` | Gazette reference code (*G.S.R. 202(E) / G.S.R. 779(E)*) |
| `is_active` | `BOOLEAN` | `DEFAULT TRUE` | Designates whether this version is currently the active statutory enforcement standard |

---

## 2. Codified Legal Metrology Rules (JSON Schema & Evaluation Engine)

The legal rules extracted from `8_1732871406.pdf` are mapped into machine-readable JSON definitions evaluated by the FastAPI compliance engine ([`backend/app/rules/legal_metrology_rules.json`](file:///d:/Devanshi/Project%2017(Parakh)/models/T1/backend/app/rules/legal_metrology_rules.json)):

```
                               ┌────────────────────────────────────────────────────────┐
                               │                 OCR & NLP EXTRACTIONS                  │
                               │  • Raw OCR Text (Google Cloud Vision)                  │
                               │  • Named Entities: MRP, QTY, DATES, CARE, MFG (BERT)   │
                               │  • Open Food Facts Registered Catalog Lookup           │
                               │  • ViT Visual Anomaly & Entropy Scores                 │
                               └──────────────────────────┬─────────────────────────────┘
                                                          │
                                                          ▼
                               ┌────────────────────────────────────────────────────────┐
                               │           FASTAPI COMPLIANCE RULE ENGINE               │
                               │  • Evaluates against active LegalDocument (law_id)     │
                               │  • Multi-clause deterministic validation & regex       │
                               │  • Severity scoring & Section 36(1) citation           │
                               └──────────────────────────┬─────────────────────────────┘
                                                          │
                                ┌─────────────────────────┴─────────────────────────┐
                                ▼                                                   ▼
                     ┌─────────────────────┐                             ┌─────────────────────┐
                     │     COMPLIANT       │                             │      VIOLATION      │
                     │ All 12 Rules Passed │                             │ Flagged with notice │
                     │ Audit trail logged  │                             │ Draft & Blockchain  │
                     └─────────────────────┘                             └─────────────────────┘
```

---

### Comprehensive Rule Specifications

#### Rule LM-001 — Name & Address of Manufacturer / Packer / Importer
* **Statutory Reference:** Chapter II, Rule 6(1)(a)
* **Statutory Text:** *"Every package shall bear thereon the name and complete address of the manufacturer, or where the manufacturer is not the packer, the name and complete address of the manufacturer and the packer, or in case of an imported package, the name and complete address of the importer."*
* **Target Entities:** `MANUFACTURER_NAME`, `MANUFACTURER_ADDRESS`
* **Validation Criteria:** Name length $\ge 3$ characters, presence of postal/location keywords (*road, street, nagar, plot, sector, dist, state, pincode, India*), 6-digit PIN code regex `\b[1-9][0-9]{5}\b`.
* **Severity:** `CRITICAL`
* **Legal Penalty:** Section 36(1) of Legal Metrology Act, 2009 (Fine up to ₹25,000 for 1st offense, up to ₹50,000 for 2nd offense, up to ₹1,00,000 or imprisonment for subsequent offenses).
* **Notice Clause:** *"Failure to declare the complete name and geographical address of the manufacturer/packer/importer on the principal display panel in violation of Rule 6(1)(a)."*

---

#### Rule LM-002 — Generic / Common Name of Commodity
* **Statutory Reference:** Chapter II, Rule 6(1)(b)
* **Statutory Text:** *"Every package shall bear thereon the common or generic names of the commodity contained in the package."*
* **Target Entities:** `GENERIC_NAME`, `PRODUCT_NAME`
* **Validation Criteria:** Specific commodity descriptor declared; vague terms (*"item", "food", "pack"*) prohibited.
* **Severity:** `HIGH`
* **Legal Penalty:** Section 36(1) of Legal Metrology Act, 2009.

---

#### Rule LM-003 — Standard Net Quantity & SI Units
* **Statutory Reference:** Chapter II, Rule 6(1)(c) read with Rule 11 & Rule 12
* **Statutory Text:** *"Every package shall bear thereon the net quantity, in terms of the standard unit of weight or measure, of the commodity contained in the package..."*
* **Target Entities:** `NET_QUANTITY`
* **Allowed SI Units:** Mass: `g`, `kg`, `mg`; Volume: `ml`, `l`, `L`, `kL`; Length: `m`, `cm`, `mm`; Area: `sq m`, `sq cm`; Count: `N`, `U`, `pieces`, `units`.
* **Prohibited Non-Standard Symbols:** `gms`, `gm`, `grm`, `kilo`, `kgs`, `ltr`, `nos`.
* **Severity:** `CRITICAL`
* **Legal Penalty:** Section 36(1) read with Rule 11 & 12.

---

#### Rule LM-004 — Month and Year of Manufacture / Packaging / Pre-Packing
* **Statutory Reference:** Chapter II, Rule 6(1)(d)
* **Statutory Text:** *"Every package shall bear thereon the month and year in which the commodity is manufactured or pre-packed or imported."*
* **Target Entities:** `MFG_DATE`, `EXPIRY_DATE`, `USE_BY_DATE`
* **Allowed Formats:** `MM/YYYY`, `MM/YY`, `MMM YYYY`, `DD/MM/YYYY`, `DD-MM-YYYY`.
* **Validation Criteria:** Date must parse correctly; manufacturing dates in the future (post-dated) are strictly prohibited.
* **Severity:** `HIGH`
* **Legal Penalty:** Section 36(1) of Legal Metrology Act, 2009.

---

#### Rule LM-005 — Maximum Retail Price (MRP) Declaration & Tax Inclusivity
* **Statutory Reference:** Chapter II, Rule 6(1)(e)
* **Statutory Text:** *"Every package shall bear thereon the retail sale price in the form 'Maximum or Max. Retail Price Rs. ...... or ₹ ...... inclusive of all taxes' or 'MRP Rs. / ₹ ...... incl. of all taxes'..."*
* **Target Entities:** `MRP`, `UNIT_SALE_PRICE`
* **Mandatory Mandatory Wording:** *"incl. of all taxes"* or *"inclusive of all taxes"*.
* **Prohibited Expressions:** *"Local taxes extra"*, *"Taxes as applicable"*, *"Excluding GST"*.
* **Severity:** `CRITICAL`
* **Legal Penalty:** Section 36(1) read with Section 18(1) of Legal Metrology Act, 2009.

---

#### Rule LM-006 — Mandatory Consumer Care Grievance Redressal Details
* **Statutory Reference:** Chapter II, Rule 6(1)(h)
* **Statutory Text:** *"Every package shall bear thereon the name, address, telephone number, and e-mail address of the person who can be or the office which can be contacted, in case of consumer complaints."*
* **Target Entities:** `CONSUMER_CARE_PHONE`, `CONSUMER_CARE_EMAIL`, `CONSUMER_CARE_ADDRESS`
* **Validation Criteria:** Valid 10-digit/1800-toll-free number + valid RFC-5322 compliant e-mail address.
* **Severity:** `CRITICAL`
* **Legal Penalty:** Section 36(1) of Legal Metrology Act, 2009.

---

#### Rule LM-007 — Country of Origin (Imported Commodities)
* **Statutory Reference:** Chapter II, Rule 6(1)(aa)
* **Statutory Text:** *"The name of the country of origin or manufacture or assembly in case of imported products shall be mentioned on the package."*
* **Target Entities:** `COUNTRY_OF_ORIGIN`
* **Severity:** `HIGH`
* **Legal Penalty:** Section 36(1) of Legal Metrology Act, 2009.

---

#### Rule LM-008 — Principal Display Panel (PDP) & Minimum Font Size
* **Statutory Reference:** Chapter II, Rule 7, Rule 9 & Schedule I (Table I & II)
* **Statutory Text:** Minimum numeral height based on net quantity (e.g., $1.0\text{ mm}$ for $\le 50\text{g}$, $2.0\text{ mm}$ for $50\text{g} - 200\text{g}$, $4.0\text{ mm}$ for $200\text{g} - 1000\text{g}$, $6.0\text{ mm}$ for $> 1000\text{g}$).
* **Severity:** `MEDIUM`

---

#### Rule LM-009 — Prohibition of Overcharging Beyond MRP / Dual MRP
* **Statutory Reference:** Chapter II, Rule 18(1)
* **Statutory Text:** Prohibition on selling above declared MRP or applying altered price stickers.
* **Severity:** `CRITICAL`
* **Legal Penalty:** Section 36(2) and Section 18(1) of Legal Metrology Act, 2009.

---

#### Rule LM-010 — Maximum Permissible Error (MPE) in Net Weight/Volume
* **Statutory Reference:** Chapter II, Rule 24 & Second Schedule
* **Statutory Text:** Tolerances for allowable deficiencies in weight/volume.
* **Severity:** `HIGH`
* **Legal Penalty:** Section 30 read with Section 36 of Legal Metrology Act, 2009.

---

#### Rule LM-011 — Open Food Facts Barcode Cross-Verification
* **Protocol Reference:** National Barcode Anti-Counterfeit Verification Protocol
* **Validation Criteria:** Validates scanned EAN/UPC against Open Food Facts master registry to detect ghost manufacturers.
* **Severity:** `CRITICAL`

---

#### Rule LM-012 — Forensic Label Tampering & Anomaly Detection
* **Protocol Reference:** Vision Transformer (ViT) Anomaly Detection Protocol
* **Validation Criteria:** Analyzes label texture, overprinting, and typography entropy with `google/vit-base-patch16-224` (Softmax entropy threshold $> 4.5$).
* **Severity:** `HIGH`

---

## 3. Database & Backend Integration

1. **ORM Layer:** [`app/models/legal_document.py`](file:///d:/Devanshi/Project%2017(Parakh)/models/T1/backend/app/models/legal_document.py) stores the version table with SHA-256 checksums.
2. **Inspection Linkage:** [`app/models/inspection.py`](file:///d:/Devanshi/Project%2017(Parakh)/models/T1/backend/app/models/inspection.py) carries `law_id` foreign key referencing the active statutory rules version.
3. **Execution Engine:** [`app/rules/engine.py`](file:///d:/Devanshi/Project%2017(Parakh)/models/T1/backend/app/rules/engine.py) reads [`legal_metrology_rules.json`](file:///d:/Devanshi/Project%2017(Parakh)/models/T1/backend/app/rules/legal_metrology_rules.json) dynamically and produces structured verdicts with statutory citations and notice text.
4. **Flutter UI Integration:** Mobile frontend renders the active statutory reference banner with official Gazette number, effective date, and document verification hash.
