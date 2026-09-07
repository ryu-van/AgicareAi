# Kiến trúc và tech stack

## Stack context

AgriCare AI là MVP Android-first: một ứng dụng Flutter, API FastAPI và dữ
liệu nông nghiệp có tính cá nhân. Quy mô hiện tại là S1, phù hợp pilot nhỏ và
phát hành theo từng đợt.

## Lựa chọn

- **Mobile:** Flutter + Dart cho Android, Material 3 và thiết kế hướng
  offline-first.
- **API:** FastAPI + Python 3.12; boundary rõ cho auth, chat/RAG, knowledge,
  journal, reminders và diagnosis.
- **Data:** Supabase Auth + PostgreSQL + Storage + pgvector là mục tiêu
  production; local demo dùng SQLite/fixture.
- **AI:** Multimodal RAG kết hợp Hybrid Search (pgvector + pg_trgm), trích xuất đặc trưng thị giác qua Gemini 1.5 Flash, cơ chế an toàn 3 tầng và trích dẫn nguồn bắt buộc (Chi tiết tại [ADR-003](adr/ADR-003-ai-rag-multimodal-architecture.md) và [Đặc tả kỹ thuật AI](ai-rag-technical-spec.md)).
- **Local sync:** SQLite + outbox/event id trên Android; server upsert
  idempotent.

## Sơ đồ

```text
Android app (Flutter)
  ├─ local SQLite/outbox ── sync ──> API (FastAPI modular monolith)
  ├─ Auth client ──────────────────> Supabase Auth
  └─ image upload ─────────────────> API -> Supabase Storage

API (FastAPI)
  ├─ Chat/RAG Engine:
  │    ├─ Safety Pre-Guardrail -> Phát hiện dịch bệnh khẩn cấp Nhóm A
  │    ├─ Vision Adapter -> Gemini 1.5 Flash (Structured Symptoms JSON)
  │    ├─ Hybrid Search -> PostgreSQL (pgvector Dense <=> + pg_trgm Sparse %)
  │    ├─ Grounded Synthesis -> Gemini 1.5 Flash + Citation/Disclaimer
  │    └─ Safety Post-Guardrail -> Kiểm tra hoạt chất cấm & Disclaimer
  ├─ Knowledge/Articles -> PostgreSQL + pgvector
  ├─ Journal/Reminder -> PostgreSQL
  └─ Expert escalation -> directory/notification adapter
```

## Dependency direction

`transport -> application -> domain -> ports`; persistence và AI providers
implement ports. UI chỉ gọi API/client services, không sở hữu policy lưu trữ.

## Alternatives

- React Native/Expo: phương án cũ, đã được thay thế sau migration.
- Web/PWA và desktop: không nằm trong phạm vi MVP Android-first; sẽ chỉ được
  xem xét lại khi pilot chứng minh nhu cầu rõ ràng.
- Microservices/Kubernetes: chưa phù hợp S1 vì không có nhu cầu scale hoặc
  ownership độc lập.

## NFR và vận hành

- Chat timeout có retry hữu hạn; thao tác ghi yêu cầu idempotency key.
- Log không chứa ảnh, token, tọa độ chính xác hoặc nội dung nhạy cảm; gắn
  request ID.
- RLS/authorization đặt tại operation boundary; service role key chỉ ở API.
- Rollout theo cohort khu vực; tắt vision bằng feature flag nếu false-positive
  vượt ngưỡng an toàn.
