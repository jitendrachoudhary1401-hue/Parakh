"""
Project PARAKH — OCR Engine

Google Cloud Vision API integration per §16.
Process: Image → OCR → Raw text → Bounding boxes → Confidence.
Stores raw results. Never fabricates OCR output.
Returns SERVICE_UNAVAILABLE if Cloud Vision is down.
"""

from __future__ import annotations

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

                if settings.google_application_credentials and os.path.exists(settings.google_application_credentials):
                    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = settings.google_application_credentials

                if settings.google_cloud_vision_key:
                    client_options = ClientOptions(api_key=settings.google_cloud_vision_key)
                    self._client = vision.ImageAnnotatorClient(client_options=client_options)
                else:
                    self._client = vision.ImageAnnotatorClient()
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
            OCRResult with raw text, words, confidence, and bounding boxes.
            Never fabricates output.
        """
        try:
            from google.cloud import vision

            client = self._get_client()
            image = vision.Image(content=image_bytes)

            # Use document_text_detection for dense text (product labels)
            response = client.document_text_detection(image=image)

            if response.error.message:
                logger.error("Cloud Vision API error: %s", response.error.message)
                return OCRResult(
                    success=False,
                    error_message=f"Cloud Vision error: {response.error.message}",
                )

            # Extract full text
            full_text = ""
            if response.full_text_annotation:
                full_text = response.full_text_annotation.text

            if not full_text.strip():
                return OCRResult(
                    success=True,
                    raw_text="",
                    confidence=0.0,
                    error_message="No text detected in image",
                )

            # Extract words with bounding boxes
            words = []
            paragraphs = []

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
                                x_coords = [v.x for v in verts]
                                y_coords = [v.y for v in verts]
                                bbox = BoundingBox(
                                    x=min(x_coords),
                                    y=min(y_coords),
                                    width=max(x_coords) - min(x_coords),
                                    height=max(y_coords) - min(y_coords),
                                    vertices=[
                                        {"x": v.x, "y": v.y} for v in verts
                                    ],
                                )

                            # Get confidence
                            word_confidence = getattr(
                                word, "confidence", 0.0
                            )

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
                "OCR extracted %d words, %d paragraphs, confidence=%.2f",
                len(words), len(paragraphs), avg_confidence,
            )

            return OCRResult(
                success=True,
                raw_text=full_text,
                words=words,
                paragraphs=paragraphs,
                confidence=avg_confidence,
            )

        except ImportError:
            logger.error("google-cloud-vision package not installed")
            return OCRResult(
                success=False,
                error_message="OCR service not configured (google-cloud-vision not installed)",
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

        Converts to bytes, then delegates to extract_text.
        """
        import cv2
        success, buffer = cv2.imencode(".png", img)
        if not success:
            return OCRResult(
                success=False,
                error_message="Failed to encode image for OCR",
            )
        return await self.extract_text(buffer.tobytes())
