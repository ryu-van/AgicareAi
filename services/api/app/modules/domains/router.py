from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.db import get_session
from services.api.app.db.models import Domain

router = APIRouter(prefix="/v1/domains", tags=["domains"])


@router.get("")
def list_domains(session: Session = Depends(get_session)) -> list[dict[str, str]]:
    domains = session.scalars(select(Domain).where(Domain.active.is_(True)).order_by(Domain.sort_order)).all()
    return [{"id": domain.id, "label": domain.label} for domain in domains]
