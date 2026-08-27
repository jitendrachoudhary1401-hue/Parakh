# Project PARAKH — Why the API Gateway Server URL is Necessary

In the **Project PARAKH** system architecture, the mobile client running on field devices does not connect directly to internal databases or private microservices. Instead, all traffic passes through a unified **FastAPI API Gateway**. 

This document outlines the operational, security, and architectural reasons why the **FastAPI Gateway Server URL** must be configured on the mobile client.

---

## 1. Architectural Architecture Overview

```mermaid
graph TD
    subgraph Mobile Edge (Field Device)
        A[Flutter Mobile Client]
    end

    subgraph NIC MeghRaj (National Cloud Gateway)
        B[FastAPI API Gateway Router]
    end

    subgraph Internal Central Services
        C[PostgreSQL - Inspections & Metadata]
        D[MongoDB - OCR Logs & Cached Schemas]
        E[Google Vision / NLP Rule Engine]
        F[Hyperledger Fabric Blockchain Node]
        G[GS1 National Barcode Registry Registry]
    end

    A -->|Single Public Port HTTPS| B
    B -->|Internal Routing| C
    B -->|Internal Routing| D
    B -->|Internal Routing| E
    B -->|Internal Routing| F
    B -->|Internal Routing| G
```

---

## 2. Core Reasons for the API Gateway

### A. Centralized Security and Authentication (Zero Trust)
* **JWT Validation**: The API Gateway intercepts all incoming requests to ensure they contain a valid JSON Web Token (JWT).
* **Role-Based Access Control (RBAC)**: Before forwarding a request to edit inspections or access notices, the Gateway verifies if the caller is an authenticated `inspector` or `admin`.
* **API Key Enforcement**: High-concurrency endpoints require the `X-API-Key` (`parakh_sec_api_key_2026`) headers, protecting backend resources from unauthorized scans.

### B. Microservice & Protocol Orchestration
* Instead of the mobile client managing multiple connection protocols, ports, and hosts (e.g., PostgreSQL connections, MongoDB sockets, Hyperledger gRPC endpoints), it makes standard REST HTTP calls to one place.
* The API Gateway acts as a dispatcher: it takes the client's request, queries PostgreSQL or runs the rule engine, commits transaction details to the Hyperledger ledger, and returns a single unified JSON response.

### C. Tamper-Proof Evidence Verification (SHA-256 Generation)
* When compliance violations are identified, the API Gateway receives the inspection data and generates a cryptographic SHA-256 hash containing:
  $$\text{Hash} = \text{SHA-256}(\text{Product Image} + \text{GPS Location} + \text{Timestamp} + \text{OCR Extracted Text})$$
* The Gateway handles the complexity of submitting this hash to the Hyperledger Fabric blockchain networks, returning a ledger receipt (`transaction_id`) back to the client.

### D. Offline Data Sync & Batch Processing
* Field officers operate in basement supermarkets and remote rural areas where network coverage is highly unstable.
* The API Gateway exposes a batch endpoint (`/sync/upload`) that allows the client to upload multiple queued local inspections at once when network connectivity is restored. The Gateway performs server-side deduplication using client-generated IDs (`client_inspection_id`), ensuring data integrity.

### E. Rate Limiting and DDoS Protection
* The API Gateway enforces request limits per inspector to prevent malicious API abuse or flooding. It implements a Redis/PostgreSQL-backed token bucket algorithm, ensuring backend reliability under high-load inspections.
