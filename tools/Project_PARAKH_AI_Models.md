# Project PARAKH — Hugging Face & AI Models Reference

---

## 1. Overview

Project PARAKH integrates pre-trained deep learning models from the **Hugging Face Hub** along with computer vision pipelines to perform automated compliance verification under the Legal Metrology (Packaged Commodities) Rules, 2011.

All models run locally via PyTorch and the Hugging Face `transformers` library. **No mock fallbacks or fabricated inference outputs are permitted**; if a model is unavailable or fails during inference, the pipeline raises an explicit error and returns `success=False` with the root cause.

---

## 2. Models Specification Matrix

| Attribute | Model 1: NLP Entity Extraction | Model 2: Vision Anomaly Detection |
| :--- | :--- | :--- |
| **Model Hub Identifier** | [`dslim/bert-base-NER`](https://huggingface.co/dslim/bert-base-NER) | [`google/vit-base-patch16-224`](https://huggingface.co/google/vit-base-patch16-224) |
| **Architecture** | BERT (Bidirectional Encoder Representations from Transformers) | ViT (Vision Transformer) |
| **Task** | Named Entity Recognition (`TokenClassification`) | Image Classification & Feature Extraction (`ImageClassification`) |
| **Backend Implementation** | `backend/app/ai/nlp_extractor.py` | `backend/app/ai/anomaly_detector.py` |
| **Config Variable** | `NER_MODEL_NAME` (in `backend/app/config.py` & `.env`) | `VIT_MODEL_NAME` (in `backend/app/config.py` & `.env`) |
| **Input Shape / Type** | Raw OCR string (truncated up to 512 tokens) | OpenCV BGR `ndarray` (auto-converted to RGB 224x224 tensor) |
| **Output** | Extracted entities with labels (`ORG`, `LOC`, `PER`) and confidence scores | Class logits, probability distribution, and packaging entropy score |
| **Error Handling Policy** | **Strict Error Reporting** (No mock/synthetic fallback) | **Strict Error Reporting** (No mock/synthetic fallback) |

---

## 3. Detailed Model Breakdown

### 3.1 Model 1: `dslim/bert-base-NER` (Named Entity Recognition)

* **Purpose:** Identifies registered manufacturer names, corporate entities (`ORG`), locations, and addresses (`LOC`/`GPE`) from noisy OCR text.
* **Pipeline:** Loaded via `transformers.pipeline("ner", model=settings.ner_model_name, aggregation_strategy="simple")`.
* **Hybrid Entity Resolution:**
  1. **Legal Metrology Regex:** Parses numeric and structured declarations (`MRP`, `NET_QUANTITY`, `MFG_DATE`, `PKG_DATE`, `EXPIRY_DATE`, `CONSUMER_CARE_PHONE`, `CONSUMER_CARE_EMAIL`).
  2. **Hugging Face NER:** Extracts unstructured entity boundaries (`MANUFACTURER_NAME`, `MANUFACTURER_ADDRESS`).
* **Entity Deduplication:** Conflicts between regex and NER matches are resolved by prioritizing higher confidence scores.
* **Failure Handling:** If the model weights cannot be downloaded or initialized, `NLPExtractionResult` returns `success=False` with the exact exception (`HuggingFace NER model failed to load`).

### 3.2 Model 2: `google/vit-base-patch16-224` (Vision Transformer)

* **Purpose:** Inspects product packaging for micro-anomalies, printing defects, tampered label overlays, and out-of-distribution visual patterns.
* **Components:**
  * Processor: `transformers.AutoImageProcessor.from_pretrained(settings.vit_model_name)`
  * Classifier: `transformers.ViTForImageClassification.from_pretrained(settings.vit_model_name)`
* **Anomaly Heuristics & Feature Analytics:**
  * **Entropy & Uncertainty Analysis:** Computes Shannon entropy over the Softmax output distribution:
    $$\text{Entropy} = -\sum p_i \ln(p_i)$$
    High entropy ($\text{Entropy} > 2.0$) with low top-1 probability ($p_{\max} < 0.3$) indicates abnormal or unseen packaging layout.
  * **Color Gradient Quadrant Analysis:** HSV variance across label quadrants.
  * **Typography Size Variance:** MSER (Maximally Stable Extremal Regions) text contour analysis.
  * **Logo Detail & Quality:** Laplacian variance on the top-third ROI.
* **Failure Handling:** If the ViT weights cannot be loaded or inference fails, `AnomalyDetectionResult` surfaces `success=False` and the underlying error message without silent suppression.

---

## 4. Configuration & Environment Variables

The model names and execution flags are defined in `.env` and `app/config.py`:

```env
# --- AI / ML Hugging Face Models ---
NER_MODEL_NAME=dslim/bert-base-NER
VIT_MODEL_NAME=google/vit-base-patch16-224
NER_CONFIDENCE_THRESHOLD=0.5
ANOMALY_DETECTION_ENABLED=true
```

---

## 5. Model Verification & Testing

To verify that both Hugging Face models are downloaded, configured, and functioning properly without mock fallbacks, run:

```bash
# Activate backend virtual environment
.\venv\Scripts\python.exe -c "
import asyncio, numpy as np
from app.ai.nlp_extractor import NLPExtractor
from app.ai.anomaly_detector import AnomalyDetector

async def test():
    # 1. Test NER
    nlp = NLPExtractor()
    res_nlp = await nlp.extract_entities('Manufactured by Britannia Industries Ltd, Bangalore, Karnataka. MRP Rs 150.00')
    print('NER Result:', res_nlp.success, [e.value for e in res_nlp.entities])
    
    # 2. Test ViT
    detector = AnomalyDetector()
    res_anomaly = await detector.detect_anomalies(np.zeros((300, 300, 3), dtype=np.uint8))
    print('ViT Result:', res_anomaly.success, res_anomaly.findings)

asyncio.run(test())
"
```
