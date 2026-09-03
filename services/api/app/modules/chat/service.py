from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import ChatCitation, ChatMessage, ChatSession, Subject
from services.api.app.modules.chat.schemas import CreateChatSessionRequest, SendChatMessageRequest
from services.api.app.modules.knowledge.service import retrieve_articles

CAUTION_KEYWORDS = ("bỏ ăn", "tiêu chảy", "ho", "vàng lá", "sâu bệnh", "thuốc", "liều")
URGENT_KEYWORDS = ("khó thở", "co giật", "chết", "dịch bệnh", "chết hàng loạt")


def create_session(session: Session, user_id: str, request: CreateChatSessionRequest) -> ChatSession:
    if request.subject_id:
        subject = session.get(Subject, request.subject_id)
        if subject is None or subject.status != "published" or subject.domain != request.domain:
            raise AppError(422, "VALIDATION_ERROR", "Đối tượng không thuộc nhánh đã chọn.")
    chat_session = ChatSession(user_id=user_id, domain=request.domain, subject_id=request.subject_id, title=request.title)
    session.add(chat_session)
    session.flush()
    return chat_session


def send_message(
    session: Session, user_id: str, session_id: str, request: SendChatMessageRequest
) -> tuple[ChatMessage, list[ChatCitation]]:
    chat_session = session.scalar(select(ChatSession).where(ChatSession.id == session_id, ChatSession.user_id == user_id))
    if chat_session is None:
        raise AppError(404, "NOT_FOUND", "Không tìm thấy cuộc trò chuyện.")
    session.add(ChatMessage(session_id=chat_session.id, role="user", content=request.content, status="completed"))
    normalized = request.content.lower()
    is_urgent = any(keyword in normalized for keyword in URGENT_KEYWORDS)
    is_caution = is_urgent or any(keyword in normalized for keyword in CAUTION_KEYWORDS)
    safety_level = "urgent" if is_urgent else "caution" if is_caution else "normal"
    articles, _ = retrieve_articles(
        session, query_text=request.content, domain=chat_session.domain, subject_id=chat_session.subject_id, limit=3
    )
    if articles:
        top = articles[0]
        source_text = top.summary or top.content
        answer = (
            f"Theo nguồn kiến thức nội bộ '{top.title}': {source_text} "
            "Đây là thông tin tham khảo, không phải chẩn đoán xác định hay chỉ định thuốc. "
            "Nếu dấu hiệu nặng lên, hãy liên hệ chuyên gia thú y hoặc cán bộ khuyến nông."
        )
    else:
        answer = (
            "Chưa có nguồn kiến thức đã duyệt phù hợp với câu hỏi này. "
            "Bạn hãy bổ sung triệu chứng, giai đoạn sinh trưởng và điều kiện nuôi trồng, "
            "hoặc liên hệ chuyên gia để được hỗ trợ."
        )
    assistant_message = ChatMessage(
        session_id=chat_session.id,
        role="assistant",
        content=answer,
        status="completed",
        safety_level=safety_level,
        needs_expert=is_caution,
    )
    chat_session.updated_at = datetime.now(timezone.utc)
    session.add(assistant_message)
    session.flush()
    citations: list[ChatCitation] = []
    for index, article in enumerate(articles):
        citation = ChatCitation(
            message_id=assistant_message.id,
            article_id=article.id,
            section=article.topic,
            relevance_score=max(0.5, 1.0 - index * 0.1),
        )
        session.add(citation)
        citations.append(citation)
    session.flush()
    return assistant_message, citations
