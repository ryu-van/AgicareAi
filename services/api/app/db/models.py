from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import JSON, Boolean, DateTime, Enum as SAEnum, ForeignKey, Integer, String, Text, Uuid, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def new_id() -> str:
    return str(uuid4())


class Base(DeclarativeBase):
    pass


AgriDomain = SAEnum("plant", "animal", name="agri_domain", create_type=False)
PublishStatus = SAEnum("draft", "in_review", "published", "archived", name="publish_status", create_type=False)
MessageRole = SAEnum("user", "assistant", name="message_role", create_type=False)
MessageStatus = SAEnum("queued", "processing", "completed", "failed", "safety_blocked", name="message_status", create_type=False)
SafetyLevel = SAEnum("normal", "caution", "urgent", name="safety_level", create_type=False)
JournalEntryType = SAEnum("observation", "treatment", "harvest", "vaccination", "feeding", name="journal_entry_type", create_type=False)


class Domain(Base):
    __tablename__ = "domains"

    id: Mapped[str] = mapped_column(String(16), primary_key=True)
    label: Mapped[str] = mapped_column(String(80), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class Subject(Base):
    __tablename__ = "subjects"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    domain: Mapped[str] = mapped_column(AgriDomain, ForeignKey("domains.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    status: Mapped[str] = mapped_column(PublishStatus, nullable=False, default="draft")


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True)
    display_name: Mapped[str | None] = mapped_column(String(120))
    phone: Mapped[str | None] = mapped_column(String(32))
    locale: Mapped[str] = mapped_column(String(16), nullable=False, default="vi-VN")
    active_domain: Mapped[str | None] = mapped_column(AgriDomain)
    region_code: Mapped[str | None] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc, onupdate=now_utc)


class Role(Base):
    __tablename__ = "roles"

    id: Mapped[str] = mapped_column(String(16), primary_key=True)
    label: Mapped[str] = mapped_column(String(80), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)


class UserRole(Base):
    __tablename__ = "user_roles"

    user_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    role_id: Mapped[str] = mapped_column(ForeignKey("roles.id", ondelete="RESTRICT"), primary_key=True)
    granted_by: Mapped[str | None] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="SET NULL"))
    granted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)


class Consent(Base):
    __tablename__ = "consents"

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    consent_type: Mapped[str] = mapped_column(String(32), nullable=False)
    version: Mapped[str] = mapped_column(String(32), nullable=False)
    accepted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class KnowledgeArticle(Base):
    __tablename__ = "knowledge_articles"

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    domain: Mapped[str] = mapped_column(AgriDomain, nullable=False)
    subject_id: Mapped[str] = mapped_column(ForeignKey("subjects.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    summary: Mapped[str | None] = mapped_column(Text)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    topic: Mapped[str | None] = mapped_column(String(120))
    growth_stage: Mapped[str | None] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(PublishStatus, nullable=False, default="draft")
    source_url: Mapped[str | None] = mapped_column(Text)
    source_name: Mapped[str | None] = mapped_column(String(160))
    reviewed_by: Mapped[str | None] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id"))
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc, onupdate=now_utc)


class ChatSession(Base):
    __tablename__ = "chat_sessions"

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    domain: Mapped[str] = mapped_column(AgriDomain, nullable=False)
    subject_id: Mapped[str | None] = mapped_column(ForeignKey("subjects.id"))
    title: Mapped[str | None] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc, onupdate=now_utc)


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    session_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("chat_sessions.id", ondelete="CASCADE"), nullable=False, index=True)
    role: Mapped[str] = mapped_column(MessageRole, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(MessageStatus, nullable=False, default="queued")
    safety_level: Mapped[str | None] = mapped_column(SafetyLevel)
    needs_expert: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)


class ChatCitation(Base):
    __tablename__ = "chat_citations"

    message_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("chat_messages.id", ondelete="CASCADE"), primary_key=True)
    article_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("knowledge_articles.id"), primary_key=True)
    section: Mapped[str | None] = mapped_column(String(120))
    relevance_score: Mapped[float | None] = mapped_column()


class JournalEntry(Base):
    __tablename__ = "journal_entries"
    __table_args__ = (UniqueConstraint("user_id", "client_event_id", name="uq_journal_user_client_event"),)

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id: Mapped[str] = mapped_column(ForeignKey("subjects.id"), nullable=False)
    entry_type: Mapped[str] = mapped_column(JournalEntryType, nullable=False)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False, default="Asia/Ho_Chi_Minh")
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    client_event_id: Mapped[str | None] = mapped_column(String(128))
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc, onupdate=now_utc)


class SyncEvent(Base):
    __tablename__ = "sync_events"
    __table_args__ = (UniqueConstraint("user_id", "event_id", name="uq_sync_user_event"),)

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    event_id: Mapped[str] = mapped_column(String(128), nullable=False)
    entity: Mapped[str] = mapped_column(String(32), nullable=False)
    operation: Mapped[str] = mapped_column(String(16), nullable=False)
    payload: Mapped[dict] = mapped_column(JSON, nullable=False)
    payload_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False)
    entity_id: Mapped[str | None] = mapped_column(String(36))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)


class IdempotencyKey(Base):
    __tablename__ = "idempotency_keys"

    user_id: Mapped[str] = mapped_column(Uuid(as_uuid=False), ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True)
    key: Mapped[str] = mapped_column(String(128), primary_key=True)
    request_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    response_status: Mapped[int] = mapped_column(Integer, nullable=False)
    response_body: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=now_utc)
