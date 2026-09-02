"""
Project PARAKH — Anomaly Detection

HuggingFace Vision Transformers (ViT) per §22.
Analyzes: logo, typography, color-gradient, packaging anomalies.
Returns "potential anomaly" — never declares "counterfeit" without
authorized verification.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import List, Optional

import numpy as np

logger = logging.getLogger("parakh.ai.anomaly")


@dataclass
class AnomalyFinding:
    """Single anomaly finding."""
    anomaly_type: str  # logo, typography, color_gradient, packaging
    description: str
    confidence: float
    is_potential_anomaly: bool
    region: Optional[dict] = None


@dataclass
class AnomalyDetectionResult:
    """Complete anomaly detection result."""
    success: bool
    findings: List[AnomalyFinding] = field(default_factory=list)
    overall_anomaly_score: float = 0.0
    error_message: Optional[str] = None


class AnomalyDetector:
    """
    ViT-based packaging anomaly detector.

    Returns potential anomalies — never makes legal determinations
    about counterfeiting.
    """

    ANOMALY_THRESHOLD = 0.6

    def __init__(self):
        self._model = None
        self._feature_extractor = None

    def _load_model(self):
        """Load the HuggingFace ViT model. Raises RuntimeError on failure, no mock fallback."""
        if self._model is None:
            from transformers import AutoImageProcessor, ViTForImageClassification
            from app.config import get_settings

            settings = get_settings()
            model_name = settings.vit_model_name
            try:
                self._feature_extractor = AutoImageProcessor.from_pretrained(model_name)
                self._model = ViTForImageClassification.from_pretrained(model_name)
                logger.info("ViT model loaded: %s", model_name)
            except Exception as exc:
                logger.error("Failed to load HuggingFace ViT model (%s): %s", model_name, exc)
                raise RuntimeError(
                    f"HuggingFace ViT model '{model_name}' failed to load: {exc}"
                ) from exc

    async def detect_anomalies(self, image: np.ndarray) -> AnomalyDetectionResult:
        """
        Analyze product packaging for potential anomalies.

        Uses:
        1. HuggingFace Vision Transformer (ViT) for deep visual feature anomaly detection.
        2. Visual consistency analysis (color gradient, typography, logo quality).

        Args:
            image: Preprocessed product image (OpenCV ndarray).
        """
        try:
            from app.config import get_settings
            settings = get_settings()

            if not settings.anomaly_detection_enabled:
                return AnomalyDetectionResult(
                    success=True,
                    findings=[],
                    error_message="Anomaly detection is disabled",
                )

            findings: List[AnomalyFinding] = []

            # 1. HuggingFace ViT Feature Analysis (No mock fallback)
            self._load_model()
            vit_findings = await self._vit_analysis(image)
            findings.extend(vit_findings)

            # 2. Color consistency analysis
            color_finding = self._analyze_color_consistency(image)
            if color_finding:
                findings.append(color_finding)

            # 3. Typography consistency analysis
            typo_finding = self._analyze_typography(image)
            if typo_finding:
                findings.append(typo_finding)

            # 4. Logo region analysis
            logo_finding = self._analyze_logo_region(image)
            if logo_finding:
                findings.append(logo_finding)

            overall_score = (
                max(f.confidence for f in findings)
                if findings else 0.0
            )

            return AnomalyDetectionResult(
                success=True,
                findings=findings,
                overall_anomaly_score=overall_score,
            )

        except Exception as exc:
            logger.exception("Anomaly detection failed: %s", exc)
            return AnomalyDetectionResult(
                success=False,
                error_message=f"Anomaly detection error: {str(exc)}",
            )

    def _analyze_color_consistency(self, image: np.ndarray) -> Optional[AnomalyFinding]:
        """Check for unusual color gradient patterns."""
        import cv2

        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        h, w = hsv.shape[:2]

        # Divide into quadrants and compare color distributions
        quadrants = [
            hsv[0:h//2, 0:w//2],
            hsv[0:h//2, w//2:w],
            hsv[h//2:h, 0:w//2],
            hsv[h//2:h, w//2:w],
        ]

        means = [np.mean(q, axis=(0, 1)) for q in quadrants]
        variations = np.std(means, axis=0)

        # High variation in hue across quadrants may indicate tampered labels
        hue_variation = variations[0] / 180.0  # Normalize hue
        if hue_variation > 0.15:
            return AnomalyFinding(
                anomaly_type="color_gradient",
                description=(
                    "Unusual color distribution detected across packaging. "
                    "This may indicate potential label inconsistency."
                ),
                confidence=min(0.9, hue_variation),
                is_potential_anomaly=True,
            )
        return None

    def _analyze_typography(self, image: np.ndarray) -> Optional[AnomalyFinding]:
        """Check for typography inconsistencies."""
        import cv2

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Detect text-like regions using MSER
        mser = cv2.MSER_create()
        regions, _ = mser.detectRegions(gray)

        if len(regions) < 3:
            return None

        # Analyze size distribution of text regions
        areas = [cv2.contourArea(r.reshape(-1, 1, 2)) for r in regions if len(r) > 4]
        if not areas:
            return None

        area_std = np.std(areas) / (np.mean(areas) + 1e-6)

        if area_std > 3.0:
            return AnomalyFinding(
                anomaly_type="typography",
                description=(
                    "Inconsistent text sizing detected on packaging. "
                    "This may warrant closer inspection."
                ),
                confidence=min(0.8, area_std / 5.0),
                is_potential_anomaly=True,
            )
        return None

    def _analyze_logo_region(self, image: np.ndarray) -> Optional[AnomalyFinding]:
        """Basic logo region quality analysis."""
        import cv2

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Look for high-detail regions (potential logos)
        laplacian = cv2.Laplacian(gray, cv2.CV_64F)
        h, w = gray.shape

        # Analyze top portion (logos typically at top)
        top_region = laplacian[0:h//3, :]
        top_quality = top_region.var()

        if top_quality < 50:
            return AnomalyFinding(
                anomaly_type="logo",
                description=(
                    "Low detail detected in expected logo region. "
                    "Logo may be blurred or of poor print quality."
                ),
                confidence=0.5,
                is_potential_anomaly=True,
            )
        return None

    async def _vit_analysis(self, image: np.ndarray) -> List[AnomalyFinding]:
        """Run ViT model for feature-level anomaly detection."""
        findings = []
        try:
            import cv2
            from PIL import Image as PILImage
            import torch

            # Convert OpenCV to PIL
            rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            pil_img = PILImage.fromarray(rgb)

            inputs = self._feature_extractor(images=pil_img, return_tensors="pt")

            with torch.no_grad():
                outputs = self._model(**inputs)
                logits = outputs.logits
                probabilities = torch.nn.functional.softmax(logits, dim=-1)

                # Check if the model is highly uncertain (potential anomaly)
                max_prob = probabilities.max().item()
                entropy = -(probabilities * probabilities.log()).sum().item()

                if max_prob < 0.3 and entropy > 2.0:
                    findings.append(AnomalyFinding(
                        anomaly_type="packaging",
                        description=(
                            "ViT model detected unusual visual features. "
                            "Packaging appearance deviates from common patterns."
                        ),
                        confidence=min(0.7, entropy / 5.0),
                        is_potential_anomaly=True,
                    ))

        except Exception as exc:
            logger.error("ViT analysis failed: %s", exc)
            raise RuntimeError(f"ViT model inference failed: {exc}") from exc

        return findings
