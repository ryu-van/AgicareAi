# AgriCare AI — Feature Breakdown

## Release slices

| ID | Feature | Priority | Release |
|---|---|---:|---|
| F0 | Identity & onboarding | Must | MVP-1 |
| F1 | Domain/farm profile | Must | MVP-1 |
| F2 | Knowledge library | Must | MVP-1 |
| F3 | Safe Vietnamese chatbot with citations | Must | MVP-1 |
| F4 | Care journal | Must | MVP-2 |
| F5 | Reminders | Must | MVP-2 |
| F6 | Offline outbox and sync | Must | MVP-2 |
| F7 | Expert escalation | Should | Pilot |
| F8 | Image diagnosis | Later | Phase 2 |
| F9 | Disease map/community | Later | Phase 3 |

## Feature → function breakdown

### F0 — Identity & onboarding

- User: sign up/sign in, choose language/domain, accept privacy and AI-safety notice, logout.
- Mobile: `submitLogin()`, `refreshSession()`, `saveOnboardingDraft()`, `completeOnboarding()`, `clearLocalSession()`.
- API: `createProfile(V)`, `getProfile()`, `updatePreferences()`, `recordConsent()`.
- Rules: service-role key chỉ ở API; consent version immutable trong audit history.

### F1 — Domain and farm profile

- User: switch `plant`/`animal`, choose supported crop/species, optionally save region/farm context.
- Mobile: `loadDomains()`, `selectActiveDomain()`, `saveFarmContext()`.
- API: `listDomains()`, `listSupportedSubjects()`, `upsertFarmContext()`.
- Rules: domain bắt buộc cho chat; không trả exact coordinates cho user khác.

### F2 — Knowledge library

- User: browse/search/filter articles, open article, view source/revision, save offline.
- Mobile: `loadSubjects()`, `searchArticles()`, `openArticle()`, `cacheArticle()`, `renderCitations()`.
- API: `listSubjects()`, `searchKnowledge()`, `getArticle()`, `listArticleRevisions()`.
- Admin: `createDraftArticle()`, `submitArticleReview()`, `publishArticle()`, `archiveArticle()`.
- Rules: chỉ `published` articles được retrieval; article cần owner, source, reviewer, locale, review date.

### F3 — Safe chatbot

- User: create conversation, ask question, add context, receive answer/citations, retry, rate answer, escalate.
- Mobile: `createChatSession()`, `sendMessage()`, `queueMessageOffline()`, `pollAnswer()`, `retryMessage()`, `submitFeedback()`.
- API: `createChatSession()`, `validateQuestion()`, `retrieveKnowledge()`, `applySafetyPolicy()`, `generateGroundedAnswer()`, `persistMessage()`, `createCitations()`, `classifyEscalation()`.
- Rules: answer phải có citations hoặc nói không tìm thấy nguồn; không definitive diagnosis; chưa kê đơn/liều thuốc.

### F4 — Care journal

- User: create/update/delete crop batch or animal group, add observation/photo, view timeline, mark resolved.
- Mobile: `createJournalEntry()`, `editJournalEntry()`, `deleteJournalEntry()`, `loadTimeline()`, `attachLocalPhoto()`.
- API: `createJournalEntry()`, `listJournalEntries()`, `updateJournalEntry()`, `deleteJournalEntry()`.
- Rules: writes cần `Idempotency-Key`; soft delete; timestamps UTC + device timezone.

### F5 — Reminders

- User: create vaccination/spraying/feeding/inspection reminder, snooze, complete, cancel.
- Mobile: `createReminder()`, `scheduleLocalNotification()`, `syncReminderState()`, `completeReminder()`.
- API: `createReminder()`, `listReminders()`, `updateReminderStatus()`, `deleteReminder()`.
- Rules: recurrence phải có timezone; local notification best-effort, server là source of truth.

### F6 — Offline outbox and sync

- User: lưu draft/journal khi offline, xem `pending/synced/failed`, retry failed items.
- Mobile: `writeOutboxEvent()`, `flushOutbox()`, `resolveSyncConflict()`, `markSyncResult()`.
- API: `syncBatch()`, `deduplicateByClientEventId()`, `applySyncOperation()`, `returnConflict()`.
- Rules: tối đa 50 events/batch; UUID event IDs; conflict phải trả về, không silently overwrite.

### F7 — Expert escalation

- User: request help, chọn dữ liệu chia sẻ, xem status, cancel request.
- API: `createEscalation()`, `listAvailableExperts()`, `getEscalation()`, `updateEscalationStatus()`.
- Rules: user explicit consent; generalize location; chưa cam kết SLA nếu chưa có owner.

### F8 — Image diagnosis (Phase 2)

- User: capture/upload image, add context, xem top-3 + confidence band, retry/escalate.
- API: `createUpload()`, `submitDiagnosis()`, `runImageQualityCheck()`, `runVisionModel()`, `calibrateConfidence()`, `applyDiagnosisSafetyGate()`.
- Release gate: chỉ supported classes có field validation Việt Nam, model card, threshold, human review và kill switch.

## Cross-cutting functions

`authorizeOperation()` · `validateIdempotencyKey()` · `redactSensitiveLogFields()` · `createAuditEvent()` · `enforceRateLimit()` · `mapDependencyFailure()`.

## Suggested API module layout

```text
services/api/app/
  core/                 settings, auth, errors, logging, rate_limit
  modules/
    identity/           router.py service.py schemas.py repository.py
    domains/            router.py service.py schemas.py repository.py
    knowledge/          router.py service.py schemas.py repository.py
    chat/               router.py service.py safety.py rag.py schemas.py
    journal/            router.py service.py schemas.py repository.py
    reminders/          router.py service.py schemas.py repository.py
    sync/               router.py service.py schemas.py
    escalation/         router.py service.py schemas.py
    diagnosis/          router.py service.py provider.py safety.py  # phase 2
  adapters/             supabase, ai_provider, notifications, storage
  db/                   models.py session.py migrations/
```

## Delivery order

1. API foundation: settings, auth, errors, request ID, health/readiness.
2. F0/F1: profile, domain and consent.
3. F2: knowledge read path with fixture data.
4. F3: chat with mocked AI, citations and safety states.
5. F4/F5: journal/reminder CRUD.
6. F6: outbox, batch sync and conflict UI.
7. F7 after expert owner/provider is identified.
8. F8 only after dataset and safety gate approval.
