from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import KnowledgeArticle, Subject


def list_subjects(session: Session, domain: str | None) -> list[Subject]:
    query = select(Subject).where(Subject.status == "published").order_by(Subject.domain, Subject.name, Subject.id)
    if domain:
        query = query.where(Subject.domain == domain)
    return list(session.scalars(query).all())


def retrieve_articles(
    session: Session,
    *,
    query_text: str | None,
    domain: str | None,
    subject_id: str | None,
    limit: int = 20,
    offset: int = 0,
) -> tuple[list[KnowledgeArticle], bool]:
    query = select(KnowledgeArticle).where(KnowledgeArticle.status == "published")
    if domain:
        query = query.where(KnowledgeArticle.domain == domain)
    if subject_id:
        query = query.where(KnowledgeArticle.subject_id == subject_id)
    if query_text:
        if session.bind is not None and session.bind.dialect.name == "postgresql":
            query = query.where(text("search_vector @@ websearch_to_tsquery('simple', :knowledge_query)")).params(
                knowledge_query=query_text
            )
        else:
            pattern = f"%{query_text}%"
            query = query.where(
                KnowledgeArticle.title.ilike(pattern)
                | KnowledgeArticle.summary.ilike(pattern)
                | KnowledgeArticle.content.ilike(pattern)
            )
    rows = list(
        session.scalars(
            query.order_by(KnowledgeArticle.published_at.desc(), KnowledgeArticle.id.desc()).offset(offset).limit(limit + 1)
        ).all()
    )
    return rows[:limit], len(rows) > limit


def get_article(session: Session, article_id: str) -> KnowledgeArticle:
    article = session.scalar(
        select(KnowledgeArticle).where(KnowledgeArticle.id == article_id, KnowledgeArticle.status == "published")
    )
    if article is None:
        raise AppError(404, "NOT_FOUND", "Không tìm thấy bài viết kiến thức.")
    return article
