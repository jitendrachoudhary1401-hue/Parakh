"""
Project PARAKH — OCR Engine

Google Cloud Vision API integration per §16.
Process: Image → OCR → Raw text → Bounding boxes → Confidence → Language.
Stores raw results. Never fabricates OCR output.
Returns SERVICE_UNAVAILABLE if Cloud Vision is down or unconfigured.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from typing import List, Optional

import numpy as np

logger = logging.getLogger("parakh.ai.ocr")


@dataclass
class BoundingBox:
    """Bounding box for detected text."""
    x: int
    y: int
    width: int
    height: int
    vertices: list = field(default_factory=list)


@dataclass
class OCRWord:
    """Single word detected by OCR."""
    text: str
    confidence: float
    bounding_box: Optional[BoundingBox] = None


@dataclass
class OCRResult:
    """Complete OCR result from Google Cloud Vision."""
    success: bool
    raw_text: str = ""
    words: List[OCRWord] = field(default_factory=list)
    paragraphs: List[str] = field(default_factory=list)
    language: Optional[str] = None
    confidence: float = 0.0
    error_message: Optional[str] = None


class OCREngine:
    """Google Cloud Vision OCR integration."""

    def __init__(self):
        self._client = None

    def _get_client(self):
        """Lazy-initialize the Vision API client using configured credentials or API key."""
        if self._client is None:
            try:
                import os
                from google.cloud import vision
                from google.api_core.client_options import ClientOptions
                from app.config import get_settings

                settings = get_settings()

                # Option 1: Inline Service Account JSON string in env
                if settings.google_cloud_vision_credentials_json:
                    try:
                        from google.oauth2 import service_account
                        info = json.loads(settings.google_cloud_vision_credentials_json)
                        creds = service_account.Credentials.from_service_account_info(info)
                        self._client = vision.ImageAnnotatorClient(credentials=creds)
                        logger.info("Initialized Google Cloud Vision client using inline JSON credentials")
                        return self._client
                    except Exception as json_err:
                        logger.warning("Failed to parse google_cloud_vision_credentials_json: %s", json_err)

                # Option 2: Path to Service Account JSON file
                if settings.google_application_credentials and os.path.exists(settings.google_application_credentials):
                    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = settings.google_application_credentials
                    self._client = vision.ImageAnnotatorClient()
                    logger.info("Initialized Google Cloud Vision client using credentials file: %s", settings.google_application_credentials)
                    return self._client

                # Option 3: Vision API Key
                if settings.google_cloud_vision_key:
                    client_options = ClientOptions(api_key=settings.google_cloud_vision_key)
                    self._client = vision.ImageAnnotatorClient(client_options=client_options)
                    logger.info("Initialized Google Cloud Vision client using API key")
                    return self._client

                # Option 4: Default Application Credentials (GCP environment)
                self._client = vision.ImageAnnotatorClient()
                logger.info("Initialized Google Cloud Vision client using Default Application Credentials")

            except Exception as exc:
                logger.error("Failed to initialize Cloud Vision client: %s", exc)
                raise
        return self._client

    async def extract_text(self, image_bytes: bytes) -> OCRResult:
        """
        Extract text from image using Google Cloud Vision API.

        Args:
            image_bytes: Raw image bytes (preprocessed by OpenCV).

        Returns:
            OCRResult with raw text, words, confidence, bounding boxes, and language.
            Never fabricates output.
        """
        if not image_bytes:
            return OCRResult(
                success=False,
                error_message="Empty image bytes provided to OCR engine",
            )

        try:
            from google.cloud import vision

            client = self._get_client()
            image = vision.Image(content=image_bytes)

            # Use document_text_detection for dense text (product packaging/labels)
            response = client.document_text_detection(image=image)

            # Fall back to text_detection if document_text_detection produces no full_text_annotation
            if not response.full_text_annotation or not response.full_text_annotation.text.strip():
                response = client.text_detection(image=image)

            if response.error.message:
                logger.error("Cloud Vision API error: %s", response.error.message)
                return OCRResult(
                    success=False,
                    error_message=f"Cloud Vision error: {response.error.message}",
                )

            # Extract full text
            full_text = ""
            if response.full_text_annotation and response.full_text_annotation.text:
                full_text = response.full_text_annotation.text
            elif response.text_annotations:
                full_text = response.text_annotations[0].description

            if not full_text.strip():
                return OCRResult(
                    success=True,
                    raw_text="",
                    confidence=0.0,
                    error_message="No text detected in image",
                )

            # Extract primary detected language
            detected_language = None
            if response.full_text_annotation and response.full_text_annotation.pages:
                page = response.full_text_annotation.pages[0]
                if page.property and page.property.detected_languages:
                    detected_language = page.property.detected_languages[0].language_code

            # Extract words with bounding boxes
            words = []
            paragraphs = []

            if response.full_text_annotation:
                for page in response.full_text_annotation.pages:
                    for block in page.blocks:
                        for paragraph in block.paragraphs:
                            para_text_parts = []
                            for word in paragraph.words:
                                word_text = "".join(
                                    symbol.text for symbol in word.symbols
                                )
                                para_text_parts.append(word_text)

                                # Get bounding box
                                bbox = None
                                if word.bounding_box and word.bounding_box.vertices:
                                    verts = word.bounding_box.vertices
                                    x_coords = [v.x for v in verts if hasattr(v, 'x')]
                                    y_coords = [v.y for v in verts if hasattr(v, 'y')]
                                    if x_coords and y_coords:
                                        min_x, max_x = min(x_coords), max(x_coords)
                                        min_y, max_y = min(y_coords), max(y_coords)
                                        bbox = BoundingBox(
                                            x=min_x,
                                            y=min_y,
                                            width=max_x - min_x,
                                            height=max_y - min_y,
                                            vertices=[
                                                {"x": getattr(v, 'x', 0), "y": getattr(v, 'y', 0)}
                                                for v in verts
                                            ],
                                        )

                                # Get confidence score
                                word_confidence = getattr(word, "confidence", 0.0)

                                words.append(OCRWord(
                                    text=word_text,
                                    confidence=word_confidence,
                                    bounding_box=bbox,
                                ))

                            paragraphs.append(" ".join(para_text_parts))

            # Overall confidence (average of word confidences)
            avg_confidence = (
                sum(w.confidence for w in words) / len(words)
                if words else 0.0
            )

            logger.info(
                "OCR extracted %d words, %d paragraphs, language=%s, confidence=%.2f",
                len(words), len(paragraphs), detected_language, avg_confidence,
            )

            return OCRResult(
                success=True,
                raw_text=full_text,
                words=words,
                paragraphs=paragraphs,
                language=detected_language,
                confidence=avg_confidence,
            )

        except ImportError:
            logger.error("google-cloud-vision package not installed")
            return OCRResult(
                success=False,
                error_message="OCR service not configured (google-cloud-vision package not installed)",
            )

        except Exception as exc:
            logger.exception("OCR extraction failed: %s", exc)
            return OCRResult(
                success=False,
                error_message=f"OCR service unavailable: {str(exc)}",
            )

    async def extract_text_from_ndarray(self, img: np.ndarray) -> OCRResult:
        """
        Extract text from an OpenCV image (numpy array).

        Converts to PNG bytes, then delegates to extract_text.
        """
        import cv2
        success, buffer = cv2.imencode(".png", img)
        if not success:
            return OCRResult(
                success=False,
                error_message="Failed to encode image for OCR",
            )
        return await self.extract_text(buffer.tobytes())
