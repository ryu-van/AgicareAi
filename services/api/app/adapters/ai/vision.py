"""Vision AI adapter for crop & livestock image analysis."""

from typing import Any


class VisionAdapter:
    def analyze_image(self, image_url: str) -> dict[str, Any]:
        return {
            "image_url": image_url,
            "detected_objects": ["leaf_spot", "foliage"],
            "confidence": 0.92,
        }
