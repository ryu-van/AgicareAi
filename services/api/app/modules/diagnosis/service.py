from typing import Any
from services.api.app.modules.diagnosis.schemas import DiagnosisRequest


def analyze_diagnosis(request: DiagnosisRequest) -> dict[str, Any]:
    return {
        "id": "diag-001",
        "disease_name": "Đốm lá vi khuẩn (Xanthomonas)",
        "confidence": 0.88,
        "treatment_recommendation": "Sử dụng chế phẩm sinh học chứa Bacillus subtilis và cắt tỉa lá bệnh.",
        "needs_expert": False,
    }
