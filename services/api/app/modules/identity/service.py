from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import Consent, Profile
from services.api.app.modules.identity.schemas import CreateConsentRequest, UpdateProfileRequest


def get_profile(session: Session, user_id: str) -> Profile:
    profile = session.get(Profile, user_id)
    if profile is None:
        raise AppError(404, "NOT_FOUND", "Không tìm thấy hồ sơ người dùng.")
    return profile


def update_profile(session: Session, user_id: str, request: UpdateProfileRequest) -> Profile:
    profile = get_profile(session, user_id)
    for field, value in request.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    session.commit()
    session.refresh(profile)
    return profile


def create_consent(session: Session, user_id: str, request: CreateConsentRequest) -> Consent:
    existing = session.scalar(
        select(Consent).where(
            Consent.user_id == user_id,
            Consent.consent_type == request.consent_type,
            Consent.version == request.version,
        )
    )
    if existing:
        return existing
    consent = Consent(user_id=user_id, **request.model_dump())
    session.add(consent)
    session.commit()
    session.refresh(consent)
    return consent
