from pydantic import BaseModel, ConfigDict


class DiagnosisRequest(BaseModel):
    image_url: str | None = None
    symptoms: str
    domain: str = "plant"


class DiagnosisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    disease_name: str
    confidence: float
    treatment_recommendation: str
    needs_expert: bool = False
