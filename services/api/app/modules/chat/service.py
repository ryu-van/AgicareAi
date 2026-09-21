from datetime import datetime, timezone
import logging
import re
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.adapters.ai.provider import AIProviderAdapter
from services.api.app.core.errors import AppError
from services.api.app.db.models import ChatCitation, ChatMessage, ChatSession, Subject
from services.api.app.modules.chat.schemas import CreateChatSessionRequest, SendChatMessageRequest
from services.api.app.modules.knowledge.service import retrieve_articles

logger = logging.getLogger(__name__)

# Catalog of Group A Emergency Diseases with domain separation
EMERGENCY_GROUP_A_ANIMAL: dict[str, str] = {
    "dịch tả lợn châu phi": "Dịch tả lợn Châu Phi (ASF)",
    "dịch tả heo châu phi": "Dịch tả lợn Châu Phi (ASF)",
    "lở mồm long móng": "Lở mồm long móng (FMD)",
    "tai xanh": "Tai xanh (PRRS thể độc lực cao)",
    "cúm gia cầm": "Cúm gia cầm (A/H5N1)",
    "h5n1": "Cúm gia cầm (A/H5N1)",
    "h5n6": "Cúm gia cầm (A/H5N6)",
    "h5n8": "Cúm gia cầm (A/H5N8)",
    "chết hàng loạt": "Dịch bệnh nguy cấp làm chết hàng loạt",
}

EMERGENCY_GROUP_A_PLANT: dict[str, str] = {
    "khảm lá sắn": "Bệnh khảm lá sắn do virus (SLCMD)",
    "chổi rồng": "Bệnh chổi rồng kiểm dịch",
    "vàng lá thối rễ": "Bệnh vàng lá thối rễ diện rộng",
    "chết hàng loạt": "Hiện tượng chết héo rũ hàng loạt diện rộng",
}

# Regex for short acronyms with word boundaries to avoid false positives (e.g. asphalt, transfers)
ACRONYM_EMERGENCY_PATTERNS = [
    (re.compile(r"\b(asf)\b", re.IGNORECASE), "Dịch tả lợn Châu Phi (ASF)"),
    (re.compile(r"\b(fmd)\b", re.IGNORECASE), "Lở mồm long móng (FMD)"),
    (re.compile(r"\b(prrs)\b", re.IGNORECASE), "Tai xanh (PRRS thể độc lực cao)"),
    (re.compile(r"\b(slcmd)\b", re.IGNORECASE), "Bệnh khảm lá sắn virus (SLCMD)"),
]

CAUTION_KEYWORDS = ("bỏ ăn", "tiêu chảy", "ho", "vàng lá", "sâu bệnh", "thuốc", "liều")
URGENT_KEYWORDS = ("khó thở", "co giật", "chết", "dịch bệnh", "chết hàng loạt")

BANNED_ACTIVE_SUBSTANCES = (
    "paraquat",
    "2,4-d",
    "chlorpyrifos",
    "carbofuran",
    "glyphosate",
)

BANNED_SUBSTANCE_REGEX = re.compile(
    r"\b(" + "|".join(re.escape(s) for s in BANNED_ACTIVE_SUBSTANCES) + r")\b",
    re.IGNORECASE,
)

SYSTEM_INSTRUCTION = (
    "Bạn là trợ lý nông nghiệp chuyên gia AgriAn, tư vấn an toàn và chính xác cho nông hộ Việt Nam.\n"
    "Quy tắc phản hồi bắt buộc:\n"
    "1. Chỉ dựa trên nguồn cẩm nang nông nghiệp chính thống được cung cấp. Tuyệt đối không tự suy diễn liều lượng hay hoạt chất ngoài cẩm nang.\n"
    "2. Phản hồi phải có 4 khối: (1) Đánh giá sơ bộ, (2) Biện pháp kỹ thuật an toàn (ưu tiên biện pháp canh tác/vệ sinh, nếu có hoạt chất chỉ dùng tên Generic), "
    "(3) Trích dẫn nguồn theo format: [Nguồn: <Tên bài>, <Cơ quan ban hành>], "
    "(4) Khuyến cáo: 'Đây là thông tin tham khảo, không phải chẩn đoán xác định hay chỉ định thuốc. Nếu dấu hiệu nặng lên, hãy liên hệ chuyên gia thú y hoặc cán bộ khuyến nông.'\n"
    "3. Cấm tuyệt đối khuyến nghị hoạt chất cấm lưu hành (Paraquat, 2,4-D, Chlorpyrifos Ethyl)."
)

_ai_provider = AIProviderAdapter()


def create_session(session: Session, user_id: str, request: CreateChatSessionRequest) -> ChatSession:
    if request.subject_id:
        subject = session.get(Subject, request.subject_id)
        if subject is None or subject.status != "published" or subject.domain != request.domain:
            raise AppError(422, "VALIDATION_ERROR", "Đối tượng không thuộc nhánh đã chọn.")
    chat_session = ChatSession(
        user_id=user_id,
        domain=request.domain,
        subject_id=request.subject_id,
        title=request.title,
    )
    session.add(chat_session)
    session.flush()
    return chat_session


def send_message(
    session: Session,
    user_id: str,
    session_id: str,
    request: SendChatMessageRequest,
    ai_provider: AIProviderAdapter | None = None,
) -> tuple[ChatMessage, list[ChatCitation]]:
    provider = ai_provider or _ai_provider
    chat_session = session.scalar(
        select(ChatSession).where(ChatSession.id == session_id, ChatSession.user_id == user_id)
    )
    if chat_session is None:
        raise AppError(404, "NOT_FOUND", "Không tìm thấy cuộc trò chuyện.")

    # Record user message
    session.add(
        ChatMessage(
            session_id=chat_session.id,
            role="user",
            content=request.content,
            status="completed",
        )
    )

    normalized = request.content.lower()

    # Tier 1 Pre-Guardrail: Check for Group A Emergency Disease (with word-boundary safety)
    detected_emergency_disease = None
    target_catalog = (
        EMERGENCY_GROUP_A_PLANT if chat_session.domain == "plant" else EMERGENCY_GROUP_A_ANIMAL
    )

    for keyword, disease_name in target_catalog.items():
        if keyword in normalized:
            detected_emergency_disease = disease_name
            break

    if not detected_emergency_disease:
        for pattern, disease_name in ACRONYM_EMERGENCY_PATTERNS:
            if pattern.search(request.content):
                detected_emergency_disease = disease_name
                break

    is_urgent = detected_emergency_disease is not None or any(keyword in normalized for keyword in URGENT_KEYWORDS)
    is_caution = is_urgent or any(keyword in normalized for keyword in CAUTION_KEYWORDS)
    safety_level = "urgent" if is_urgent else "caution" if is_caution else "normal"

    citations: list[ChatCitation] = []

    # If Emergency Disease detected: Short-circuit with domain-appropriate emergency protocol
    if detected_emergency_disease:
        if chat_session.domain == "plant":
            answer = (
                f"🚨 CẢNH BÁO NGUY CẤP: Dấu hiệu nghi ngờ dịch bệnh thực vật kiểm dịch ({detected_emergency_disease}). "
                "Theo quy định kiểm dịch thực vật quốc gia, TUYỆT ĐỐI KHÔNG tự ý mua bán hay di chuyển cây giống, tàn dư bệnh. "
                "Yêu cầu cách ly khu vực canh tác và báo khẩn cấp cho Chi cục Trồng trọt & Bảo vệ Thực vật hoặc "
                "Cán bộ Khuyến nông địa phương để kiểm tra."
            )
        else:
            answer = (
                f"🚨 CẢNH BÁO NGUY CẤP: Phát hiện dấu hiệu nghi ngờ dịch bệnh nhóm A ({detected_emergency_disease}). "
                "Theo quy định kiểm dịch quốc gia, TUYỆT ĐỐI KHÔNG tự ý mua thuốc hay sử dụng kháng sinh/hóa chất tại chỗ. "
                "Yêu cầu cách ly đàn/khu vực chuồng nuôi ngay lập tức, ngừng vận chuyển hay giết mổ, "
                "và thông báo khẩn cấp cho Trạm Chăn nuôi & Thú y hoặc Cán bộ Khuyến nông địa phương để kiểm định."
            )
    else:
        # Tier 3: Retrieval Engine
        articles, _ = retrieve_articles(
            session,
            query_text=request.content,
            domain=chat_session.domain,
            subject_id=chat_session.subject_id,
            limit=3,
        )

        if articles:
            context_articles: list[dict[str, Any]] = [
                {
                    "id": a.id,
                    "title": a.title,
                    "summary": a.summary,
                    "content": a.content,
                    "topic": a.topic,
                }
                for a in articles
            ]

            # Tier 4: Grounded Synthesis via AI Provider
            answer = provider.generate_completion(
                prompt=request.content,
                system_instruction=SYSTEM_INSTRUCTION,
                context_articles=context_articles,
            )

            # Tier 5: Post-Guardrail Verification (Banned Substances Redaction)
            if BANNED_SUBSTANCE_REGEX.search(answer):
                answer = BANNED_SUBSTANCE_REGEX.sub("[CẢNH BÁO: HOẠT CHẤT ĐÃ BỊ CẤM LƯU HÀNH]", answer)

            # Ensure safety disclaimer exists
            if "không phải chẩn đoán xác định" not in answer:
                answer += (
                    " Đây là thông tin tham khảo, không phải chẩn đoán xác định hay chỉ định thuốc. "
                    "Nếu dấu hiệu nặng lên, hãy liên hệ chuyên gia thú y hoặc cán bộ khuyến nông."
                )

            # Build citations
            for index, article in enumerate(articles):
                citation = ChatCitation(
                    message_id="",  # will be assigned below
                    article_id=article.id,
                    section=article.topic,
                    relevance_score=max(0.5, 1.0 - index * 0.1),
                )
                citations.append(citation)
        else:
            answer = (
                "Chưa có nguồn kiến thức đã duyệt phù hợp với câu hỏi này. "
                "Bạn hãy bổ sung triệu chứng, giai đoạn sinh trưởng và điều kiện nuôi trồng, "
                "hoặc liên hệ chuyên gia để được hỗ trợ."
            )

    # Persist assistant message
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

    for citation in citations:
        citation.message_id = assistant_message.id
        session.add(citation)

    session.flush()
    return assistant_message, citations
