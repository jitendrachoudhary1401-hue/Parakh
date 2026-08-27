# **Mobile App Page Architecture (Inspector Workflow)**
**Project PARAKH: Advanced Legal Metrology Compliance System**

---

### **1. Authentication & Onboarding**
* **Splash Screen:** Displays the PARAKH logo and Ministry branding while the app initializes.
* **Login Screen:** Secure login for Enforcement Officials using Official ID, Password, and OTP verification.
* **Biometric Setup/Unlock:** Prompts for FaceID or Fingerprint for quick, secure access during fieldwork.

### **2. Dashboard & Navigation**
* **Inspector Dashboard (Home):** * Quick actions: "New Scan", "View Drafts", "Recent Inspections".
    * Daily stats (e.g., *15 Compliant, 3 Violations Detected*).
* **Offline Sync Hub:** A dedicated screen showing pending uploads. Crucial for when inspectors scan products in retail basements or rural areas with low network connectivity.

### **3. Core Scanning Engine**
* **AR Live Camera Screen:** The primary workspace. Features a live camera feed with AR bounding boxes (green/red) projecting onto products, auto-focus, and flash toggles.
* **Barcode/QR Scanner:** A quick-toggle screen to scan barcodes to fetch Open Food Facts manufacturer registry data.
* **Manual Upload/Gallery:** Allows inspectors to select photos already taken on their device camera roll.

### **4. Analysis & Enforcement**
* **AI Extraction Review:** Displays the flattened image alongside the OCR/NLP extracted data (MRP, Net Wt., Dates, etc.) for a quick visual sanity check.
* **Compliance Verdict Screen:**
    * **Green (Pass):** Simple success animation and a "Log Inspection" button.
    * **Red (Fail):** Highlights the specific Legal Metrology rules broken (e.g., *Rule 3: Missing Consumer Care Email*).
* **Evidence & Report Generator:** The screen where the inspector finalizes the violation. Includes a preview of the cryptographic hash (Blockchain receipt) and a button to "Generate PDF Notice."

### **5. Records & Settings**
* **Inspection History (Ledger):** A searchable list of all past scans, filterable by date, location, and compliance status.
* **Notice Viewer:** An in-app PDF viewer to read the generated legal violation reports.
* **Profile & Settings:** Inspector details, assigned geographical zone, dark/light mode toggle, and language preferences (English/Hindi).
