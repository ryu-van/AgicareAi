from fastapi import APIRouter, Depends
from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.modules.diagnosis.schemas import DiagnosisRequest, DiagnosisResponse
from services.api.app.modules.diagnosis.service import analyze_diagnosis

router = APIRouter(prefix="/v1/diagnosis", tags=["diagnosis"])


@router.post("/analyze", response_model=DiagnosisResponse)
def run_diagnosis(
    request: DiagnosisRequest,
    user: UserPrincipal = Depends(get_current_user),
) -> DiagnosisResponse:
    result = analyze_diagnosis(request)
    return DiagnosisResponse.model_validate(result)
