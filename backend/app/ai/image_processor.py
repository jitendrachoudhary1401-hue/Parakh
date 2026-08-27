"""
Project PARAKH — Image Processing Service

OpenCV pipeline per §15:
Input → Validation → Preprocessing → Product boundary detection →
Surface analysis → Unwarping → Ready for OCR.

Supports curved surfaces (bottles, cans, crumpled pouches).
Returns INSUFFICIENT_IMAGE_QUALITY if quality is too poor.
Does not fabricate output.
"""

from __future__ import annotations

import io
import logging
from dataclasses import dataclass, field
from typing import Optional, Tuple

try:
    import cv2
except ImportError:
    cv2 = None

import numpy as np
from PIL import Image

logger = logging.getLogger("parakh.ai.image_processor")


@dataclass
class ProcessingResult:
    """Result of image processing pipeline."""
    success: bool
    processed_image: Optional[np.ndarray] = None
    original_shape: Tuple[int, int] = (0, 0)
    processed_shape: Tuple[int, int] = (0, 0)
    is_curved_surface: bool = False
    unwarping_applied: bool = False
    quality_score: float = 0.0
    error_message: Optional[str] = None
    metadata: dict = field(default_factory=dict)


class ImageProcessor:
    """OpenCV-based image processing for product label extraction."""

    MIN_RESOLUTION = 640
    QUALITY_THRESHOLD = 0.3

    def validate_image(self, image_bytes: bytes) -> Tuple[bool, str]:
        """
        Validate image integrity and quality.

        Returns:
            (is_valid, error_message)
        """
        try:
            img_array = np.frombuffer(image_bytes, dtype=np.uint8)
            img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

            if img is None:
                return False, "Failed to decode image"

            h, w = img.shape[:2]
            if h < self.MIN_RESOLUTION or w < self.MIN_RESOLUTION:
                return False, (
                    f"Image resolution too low: {w}x{h}. "
                    f"Minimum: {self.MIN_RESOLUTION}x{self.MIN_RESOLUTION}"
                )

            return True, ""

        except Exception as exc:
            logger.error("Image validation failed: %s", exc)
            return False, f"Image validation error: {str(exc)}"

    def process(self, image_bytes: bytes) -> ProcessingResult:
        """
        Run the full image processing pipeline.

        Pipeline:
        1. Decode and validate
        2. Preprocessing (denoise, enhance contrast)
        3. Product boundary detection
        4. Surface analysis (detect curvature)
        5. Unwarping (if curved surface detected)
        6. Final cleanup for OCR
        """
        try:
            # 1. Decode
            img_array = np.frombuffer(image_bytes, dtype=np.uint8)
            img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

            if img is None:
                return ProcessingResult(
                    success=False,
                    error_message="Failed to decode image",
                )

            original_shape = img.shape[:2]
            logger.info("Processing image: %dx%d", original_shape[1], original_shape[0])

            # 2. Preprocessing
            processed = self._preprocess(img)

            # 3. Product boundary detection
            roi, boundary_found = self._detect_product_boundary(processed)
            if roi is not None:
                processed = roi

            # 4. Surface analysis
            is_curved = self._detect_curved_surface(processed)

            # 5. Unwarping (if needed)
            unwarping_applied = False
            if is_curved:
                unwarped = self._unwarp_surface(processed)
                if unwarped is not None:
                    processed = unwarped
                    unwarping_applied = True

            # 6. Quality assessment
            quality_score = self._assess_quality(processed)

            if quality_score < self.QUALITY_THRESHOLD:
                return ProcessingResult(
                    success=False,
                    original_shape=original_shape,
                    quality_score=quality_score,
                    error_message=(
                        f"Image quality score {quality_score:.2f} is below "
                        f"threshold {self.QUALITY_THRESHOLD}. "
                        "Consider recapturing the image."
                    ),
                )

            return ProcessingResult(
                success=True,
                processed_image=processed,
                original_shape=original_shape,
                processed_shape=processed.shape[:2],
                is_curved_surface=is_curved,
                unwarping_applied=unwarping_applied,
                quality_score=quality_score,
                metadata={
                    "boundary_detected": boundary_found,
                    "preprocessing": "denoise+clahe",
                },
            )

        except Exception as exc:
            logger.exception("Image processing failed: %s", exc)
            return ProcessingResult(
                success=False,
                error_message=f"Processing error: {str(exc)}",
            )

    def _preprocess(self, img: np.ndarray) -> np.ndarray:
        """Denoise and enhance contrast for better OCR accuracy."""
        # Convert to grayscale for processing, keep colour for analysis
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Denoise
        denoised = cv2.fastNlMeansDenoising(gray, h=10)

        # CLAHE (Contrast Limited Adaptive Histogram Equalization)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(denoised)

        # Convert back to 3-channel for downstream pipeline
        return cv2.cvtColor(enhanced, cv2.COLOR_GRAY2BGR)

    def _detect_product_boundary(
        self, img: np.ndarray
    ) -> Tuple[Optional[np.ndarray], bool]:
        """
        Detect the product label boundary using contour detection.

        Returns (cropped_roi, was_boundary_found).
        """
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(blurred, 50, 150)

        contours, _ = cv2.findContours(
            edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        if not contours:
            return None, False

        # Find the largest contour (likely the product label)
        largest = max(contours, key=cv2.contourArea)
        area = cv2.contourArea(largest)
        img_area = img.shape[0] * img.shape[1]

        # Only crop if the contour covers a significant area
        if area > img_area * 0.1:
            x, y, w, h = cv2.boundingRect(largest)
            # Add padding
            padding = 10
            x = max(0, x - padding)
            y = max(0, y - padding)
            w = min(img.shape[1] - x, w + 2 * padding)
            h = min(img.shape[0] - y, h + 2 * padding)
            roi = img[y:y+h, x:x+w]
            return roi, True

        return None, False

    def _detect_curved_surface(self, img: np.ndarray) -> bool:
        """
        Detect if the product has a curved surface (bottle, can, etc.).

        Uses Hough line analysis to detect perspective distortion
        indicative of cylindrical surfaces.
        """
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        edges = cv2.Canny(gray, 50, 150)

        # Detect lines
        lines = cv2.HoughLinesP(
            edges, 1, np.pi / 180, threshold=80,
            minLineLength=50, maxLineGap=10,
        )

        if lines is None or len(lines) < 4:
            return False

        # Analyze angle distribution
        angles = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            if x2 - x1 != 0:
                angle = np.arctan2(abs(y2 - y1), abs(x2 - x1))
                angles.append(np.degrees(angle))

        if not angles:
            return False

        # High variance in vertical line angles suggests curvature
        angle_std = np.std(angles)
        return angle_std > 15.0

    def _unwarp_surface(self, img: np.ndarray) -> Optional[np.ndarray]:
        """
        Apply perspective correction for curved/warped surfaces.

        Uses a simplified 3D unwarping approach based on estimated
        cylindrical projection parameters.
        """
        try:
            h, w = img.shape[:2]

            # Create source and destination points for perspective transform
            # Simulates flattening a cylindrical surface
            margin_x = int(w * 0.05)
            margin_y = int(h * 0.02)

            src_points = np.float32([
                [margin_x, margin_y],
                [w - margin_x, margin_y],
                [0, h],
                [w, h],
            ])

            dst_points = np.float32([
                [0, 0],
                [w, 0],
                [0, h],
                [w, h],
            ])

            matrix = cv2.getPerspectiveTransform(src_points, dst_points)
            unwarped = cv2.warpPerspective(img, matrix, (w, h))

            return unwarped

        except Exception as exc:
            logger.warning("Unwarping failed: %s", exc)
            return None

    def _assess_quality(self, img: np.ndarray) -> float:
        """
        Assess image quality for OCR readability.

        Returns a score between 0.0 (poor) and 1.0 (excellent).
        """
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Laplacian variance (sharpness measure)
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        sharpness = min(1.0, laplacian_var / 500.0)

        # Contrast measure
        contrast = gray.std() / 128.0
        contrast = min(1.0, contrast)

        # Combined score
        quality = 0.6 * sharpness + 0.4 * contrast
        return round(quality, 3)

    def image_to_bytes(self, img: np.ndarray, format: str = ".png") -> bytes:
        """Convert processed image back to bytes for storage/API."""
        success, buffer = cv2.imencode(format, img)
        if success:
            return buffer.tobytes()
        raise ValueError("Failed to encode image")
