# AgriCare AI API Contract — Draft v1

## Conventions

- Base path: `/v1`; JSON UTF-8; timestamps ISO-8601 UTC.
- Auth: `Authorization: Bearer <Supabase access token>`; local demo also accepts `Bearer dev:<UUID>` only when explicitly enabled.
- Server always returns `X-Request-Id`; client may send one.
- Create/send/sync writes require `Idempotency-Key`.
- Pagination uses `cursor` + `limit` (default 20, max 50), ordered by `created_at desc, id desc`.
- `user_id` is derived from the token, never accepted from the client.
- Knowledge public responses contain only `published` articles; local chat is deterministic and cites the retrieved article IDs.
- Breaking API changes require `/v2`; additive fields are allowed in `/v1`.

## Stable error envelope

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dữ liệu không hợp lệ.",
    "request_id": "req_01H...",
    "fields": [{"field": "content", "reason": "required"}]
  }
}
```

Codes: `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `VALIDATION_ERROR`, `CONFLICT`, `RATE_LIMITED`, `DEPENDENCY_TIMEOUT`, `SAFETY_BLOCKED`, `INTERNAL_ERROR`.

## Endpoint map

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | None | Liveness |
| GET | `/ready` | None | Dependency readiness |
| GET/PATCH | `/v1/me` | User | Read/update profile |
| POST | `/v1/me/consents` | User | Record consent version |
| GET | `/v1/domains` | Optional | Plant/animal domains |
| GET | `/v1/subjects` | Optional | Supported crops/species |
| GET | `/v1/knowledge/articles` | Optional | Search/browse knowledge |
| GET | `/v1/knowledge/articles/{article_id}` | Optional | Article detail/citations |
| POST/GET | `/v1/chat/sessions` | User | Create/list conversations |
| POST/GET | `/v1/chat/sessions/{session_id}/messages` | User | Send/list messages |
| POST | `/v1/chat/messages/{message_id}/feedback` | User | Rate answer |
| POST/GET | `/v1/journal/entries` | User | Create/list timeline |
| PATCH/DELETE | `/v1/journal/entries/{entry_id}` | User | Edit/soft delete |
| POST/GET | `/v1/reminders` | User | Create/list reminders |
| PATCH/DELETE | `/v1/reminders/{reminder_id}` | User | Complete/update/cancel |
| POST | `/v1/sync/batch` | User | Apply offline events |
| GET | `/v1/sync/status` | User | Pending/conflict summary |
| POST | `/v1/escalations` | User | Request expert help |
| GET | `/v1/escalations/{id}` | User | Escalation status |
| POST | `/v1/diagnoses` | User | Phase 2 only |

### Knowledge feed context

`GET /v1/knowledge/articles` trả về feed chung khi không truyền `domain`.
Mỗi article luôn có trường `domain` để client gắn nhãn hoặc dùng bộ lọc.
Tham số `domain=plant|animal` chỉ dùng khi người dùng chủ động lọc nội dung.

Profile không còn trả về hoặc cập nhật `active_domain`. Ngữ cảnh chỉ được chọn
khi tạo một chat session qua `POST /v1/chat/sessions`.

## Core request/response examples

### Create chat session

`POST /v1/chat/sessions` with `Idempotency-Key`:

```json
{"domain":"animal","subject_id":"chicken","title":"Gà có triệu chứng lạ"}
```

`201`:

```json
{"id":"cs_123","domain":"animal","subject_id":"chicken","title":"Gà có triệu chứng lạ","created_at":"2026-08-25T10:00:00Z"}
```

### Send chat message

`POST /v1/chat/sessions/{session_id}/messages` with `Authorization` and `Idempotency-Key`:

```json
{"content":"Gà bỏ ăn và ủ rũ hai ngày, tôi nên kiểm tra gì?","context":{"age_days":45,"count":20}}
```

`202`:

```json
{
  "message_id":"msg_123","status":"completed","role":"assistant",
  "answer":"Chưa thể kết luận bệnh chỉ từ mô tả này...",
  "safety_level":"caution","needs_expert":true,
  "citations":[{"article_id":"art_123","title":"...","section":"Dấu hiệu","revision":"2026-08-20"}],
  "created_at":"2026-08-25T10:01:00Z"
}
```

Statuses: `queued`, `processing`, `completed`, `failed`, `safety_blocked`. No fabricated answer on provider failure.

### Journal entry

```json
{
  "subject_id":"chicken","entry_type":"observation",
  "observed_at":"2026-08-25T08:30:00Z","timezone":"Asia/Ho_Chi_Minh",
  "title":"Đàn gà bỏ ăn","notes":"Khoảng 3 con có biểu hiện...",
  "client_event_id":"evt_123"
}
```

Validation: `notes` max 5,000 chars; attachments upload separately; duplicate event with different payload returns `409 CONFLICT`.

### Offline sync

`POST /v1/sync/batch`:

```json
{"events":[{"event_id":"evt_123","entity":"journal_entry","operation":"upsert","payload":{}}]}
```

`200`:

```json
{"results":[{"event_id":"evt_123","status":"applied","entity_id":"je_123"}],"server_cursor":"cur_456"}
```

Per-event statuses: `applied`, `duplicate`, `conflict`, `rejected`. Partial success is expected; client replays only failed events.

## Authorization matrix

| Resource | Anonymous | User | Expert | Editor | Admin |
|---|---|---|---|---|---|
| Published domains/articles | Read | Read | Read | Manage | Manage |
| Own chat/journal/reminders | No | CRUD own | No default access | No default access | Support only when explicitly shared |
| Escalations | No | Create/read own | Assigned cases only | Read when explicitly shared | Manage/audit |
| Draft knowledge | No | No | Review when assigned | Create/review/publish | Manage |
| Diagnosis | No | Phase 2 supported classes | Review assigned cases | No default access | Review/audit |

## Limits and failure behavior

- Chat: 20 requests/minute/user; `429` includes `Retry-After`.
- Sync: max 50 events or 256 KB/request.
- Text: 1–5,000 characters; whitespace-only rejected.
- AI: 15-second timeout/attempt, one safe retry for read-only generation.
- DB/storage timeout: `DEPENDENCY_TIMEOUT`; never fabricate success.
- Logs redact tokens, image bytes, exact coordinates, phone/email and full user text.
