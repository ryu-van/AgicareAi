# Kiến trúc và tech stack

## Stack context

Hiện trạng: thư mục đích chưa có manifest, test hoặc deployable; Node.js 22.18.0, npm 10.9.3 và Python 3.12.0 khả dụng. Phân loại: S1 — sản phẩm mới, có mobile, API, dữ liệu cá nhân và AI nhưng MVP pilot nhỏ.

## Lựa chọn

- **Mobile:** Flutter + Dart; một codebase Android/iOS, Material 3 và phù hợp offline-first.
- **API:** FastAPI + Python 3.12; boundary rõ cho auth, chat/RAG, knowledge, journal, reminders, diagnosis.
- **Data:** Supabase Auth + PostgreSQL + Storage + pgvector; giảm số dịch vụ phải vận hành, giữ dữ liệu quan hệ và vector cùng nơi.
- **AI:** RAG với citation bắt buộc; vision adapter là module thay thế được, chỉ bật cho classes có đánh giá ngoài thực địa.
- **Local sync:** SQLite + outbox/event id trên mobile; server upsert idempotent.

## Sơ đồ

```text
Mobile (Flutter)
  ├─ local SQLite/outbox ── sync ──> API (FastAPI modular monolith)
  ├─ Auth client ────────────────> Supabase Auth
  └─ image upload ───────────────> API -> Supabase Storage

API
  ├─ Chat/RAG -> knowledge sources -> pgvector/Postgres
  ├─ Diagnosis adapter -> vision provider/model (phase 2)
  ├─ Journal/Reminder -> Postgres
  └─ Expert escalation -> directory/notification adapter (phase 2)
```

## Dependency direction

`transport -> application -> domain -> ports`; persistence and AI providers implement ports. UI chỉ gọi API/client services, không sở hữu policy lưu trữ.

## Alternatives

- React Native/Expo: phương án cũ, đã được thay thế sau migration.
- Next.js web/PWA: dễ triển khai nhưng camera/offline/background sync kém tự nhiên hơn native mobile cho vùng mạng yếu.
- Microservices/Kubernetes: không phù hợp S1 vì chưa có nhu cầu scale/ownership độc lập.

## NFR và vận hành

- Chat timeout có retry hữu hạn; không retry các thao tác ghi nếu thiếu idempotency key.
- Log không chứa ảnh, token, tọa độ chính xác hoặc nội dung nhạy cảm; gắn request id.
- RLS/authorization tại operation boundary; service role key chỉ ở API.
- Rollout theo cohort khu vực; tắt vision bằng feature flag nếu false-positive vượt ngưỡng an toàn.
