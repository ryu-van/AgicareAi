from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from services.api.app.core.db import get_session
from services.api.app.modules.knowledge.schemas import (
    KnowledgeArticleListResponse,
    KnowledgeArticleResponse,
    SubjectResponse,
)
from services.api.app.modules.knowledge.service import get_article, list_subjects, retrieve_articles

router = APIRouter(prefix="/v1", tags=["knowledge"])


@router.get("/subjects", response_model=list[SubjectResponse])
def subjects(
    domain: str | None = Query(default=None, pattern="^(plant|animal)$"),
    session: Session = Depends(get_session),
) -> list[SubjectResponse]:
    return [SubjectResponse.model_validate(item) for item in list_subjects(session, domain)]


@router.get("/knowledge/articles", response_model=KnowledgeArticleListResponse)
def articles(
    q: str | None = Query(default=None, max_length=200),
    domain: str | None = Query(default=None, pattern="^(plant|animal)$"),
    subject_id: str | None = Query(default=None, max_length=64),
    limit: int = Query(default=20, ge=1, le=50),
    cursor: int = Query(default=0, ge=0),
    session: Session = Depends(get_session),
) -> KnowledgeArticleListResponse:
    items, has_more = retrieve_articles(
        session,
        query_text=q.strip() if q and q.strip() else None,
        domain=domain,
        subject_id=subject_id,
        limit=limit,
        offset=cursor,
    )
    return KnowledgeArticleListResponse(
        items=[KnowledgeArticleResponse.model_validate(item) for item in items],
        next_cursor=str(cursor + limit) if has_more else None,
    )


@router.get("/knowledge/articles/{article_id}", response_model=KnowledgeArticleResponse)
def article_detail(article_id: str, session: Session = Depends(get_session)) -> KnowledgeArticleResponse:
    return KnowledgeArticleResponse.model_validate(get_article(session, article_id))
