# **PROJECT PARAKH** 

Product Requirements Document (PRD) 

Software System for Legal Metrology Compliance Checking 

#### **Problem Statement ID:** 26034 

**Organization:** Ministry of Consumer Affairs, Food & Public Distribution (DoCA) 

**Theme:** Agriculture, FoodTech & Rural Development 

#### **Project Team:** 

Nikhil Pandey, Tanushree, Sudha, Akshay Paswan, Jitendra Choudhary, Aaryan Kasaudhan 

Page 1 

## **1. Introduction** 

### **1.1 Purpose** 

This Product Requirements Document (PRD) outlines the features, architectural guidelines, and behavioral expectations for Project PARAKH. The system is designed to automate and streamline the compliance checking of packaged commodities against the Legal Metrology (Packaged Commodities) Rules, 2011. 

### **1.2 Background & Scope** 

Currently, the enforcement of mandatory packaging declarations—such as Maximum Retail Price (MRP), Net Quantity, Manufacturing/Expiry Dates, and Consumer Care details—relies on manual inspection. This manual dependency limits the capacity of enforcement agencies to monitor the vast array of products available in the market. 

Project PARAKH aims to deploy an intelligent software system capable of scanning product labels, automatically extracting relevant textual information, and evaluating compliance through a rules-based engine. The system will operate via mobile applications for on-ground enforcement and a centralized web dashboard for administrative oversight. 

## **2. User Personas** 

|**Persona**|**Description & Goals**|
|---|---|
|**Enforcement Ofcial**|On-ground inspectors who scan physical products in retail environments. They<br>need a fast, reliable mobile interface that provides real-time compliance<br>verdicts and generates ofcial violation reports on the spot.|
|**Nodal Ofcer (Admin)**|Command-center users who monitor aggregate data. They require analytical<br>dashboards, predictive heatmaps for non-compliance trends, and access to<br>the evidentiary ledger for legal actions.|
|**Citizen (Optional)**|Everyday consumers empowered to report suspicious packaging. They need<br>a simplifed interface to upload images of non-compliant products for<br>administrative triage.|



Page 2 

## **3. Functional Requirements** 

### **3.1 Input & Data Capture (Mobile Application)** 

- **Real-time Scanning:** The mobile application must support live camera feeds with augmented reality overlays to guide the user in capturing the optimal angle of the packaging. 

- **Barcode Recognition:** The application must automatically read standard product barcodes to identify the registered manufacturer details from global databases. 

- **Offline Capability:** The capture module must allow image capture and temporary local storage when operating in low-connectivity retail areas, syncing data automatically once the connection is restored. 

### **3.2 Intelligent Data Extraction (Vision Engine)** 

- **Surface Unwarping:** The system must digitally flatten images of curved or crumpled packaging (e.g., cylindrical bottles, snack pouches) to ensure accurate text recognition. 

- **Optical Character Extraction:** The core engine must extract all visible text from the processed product images. 

- **Entity Categorization:** Natural language processing algorithms must categorize the extracted text into specific fields (e.g., classifying numeric values with currency symbols as MRP, or dates as manufacturing/expiry details). 

### **3.3 Compliance Validation (Rule Engine)** 

The system must cross-reference the extracted data against the Legal Metrology Rules. The rules engine must automatically validate the following criteria: 

- Presence and correctness of the MRP declaration (including required prefixes). 

- 

- Presence of Net Quantity and verification of standard unit formatting. 

- 

- Presence of Month and Year of Manufacture or Packaging. 

- 

- Completeness of Consumer Care contact information (mandatory Phone number and Email/Address). 

- 

- Verification that the extracted manufacturer details align with the scanned barcode registry. 

Page 3 

### **3.4 Evidentiary Ledger & Reporting** 

**Legal Admissibility:** Evidence collected by the system may be used in legal proceedings. Thus, strict data integrity measures are mandatory. 

- **Immutable Ledger:** For every detected violation, the system must generate a cryptographic hash of the image, timestamp, GPS coordinates, and extracted text data, storing it in an immutable digital ledger to prevent evidence tampering. 

- **Automated Document Generation:** The system must automatically generate standard legal notices incorporating the highlighted product images (with bounding boxes identifying specific violations) and detailed compliance results. 

### **3.5 Centralized Web Dashboard** 

- **Inspection History:** A searchable, filtered repository of all scanned products, both compliant and non-compliant. 

- **Predictive Analytics:** Visual heatmaps that display geographic areas or product categories with historically high violation rates. 

- **Triage System:** An interface for administrators to review, approve, or reject violation reports submitted by Citizens. 

## **4. Non-Functional Requirements (NFRs)** 

- **Performance:** The time from image capture to compliance verdict generation should not exceed 5 seconds under standard network conditions. 

- **Scalability:** The architecture must support concurrent usage by thousands of enforcement officials nationwide without degradation of service. 

- **Security:** All data in transit and at rest must be encrypted. Role-based access control (RBAC) must strictly govern who can view, edit, or delete records. 

- **Usability:** The mobile interface must be intuitive, requiring less than 30 minutes of training for a nontechnical field officer to operate proficiently. 

- **Platform Independence:** The mobile application must function seamlessly on major operating systems, and the web dashboard must be supported on all modern web browsers. 

Page 4 

