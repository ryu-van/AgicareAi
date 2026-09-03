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
- **AI:** RAG có citation bắt buộc; vision adapter chỉ bật cho lớp đối tượng
  đã được đánh giá thực địa.
- **Local sync:** SQLite + outbox/event id trên Android; server upsert
  idempotent.

## Sơ đồ

```text
Android app (Flutter)
  ├─ local SQLite/outbox ── sync ──> API (FastAPI modular monolith)
  ├─ Auth client ──────────────────> Supabase Auth
  └─ image upload ─────────────────> API -> Supabase Storage

API
  ├─ Chat/RAG -> knowledge sources -> pgvector/Postgres
  ├─ Diagnosis adapter -> vision provider/model (phase 2)
  ├─ Journal/Reminder -> Postgres
  └─ Expert escalation -> directory/notification adapter (phase 2)
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
