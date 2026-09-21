# AgriAn — Báo Cáo & Theo Dõi Tiến Trình Dự Án (Project Progress Tracker)

> **Cập nhật lần cuối:** 07/09/2026  
> **Thương hiệu chính thức:** **AgriAn** (*"Vụ mùa an tâm, nông gia thịnh vượng"*)  
> **Logo:** Concept 2 — Chiếc Khiên Bảo Vệ Đa Nhánh (Cây trồng & Vật nuôi)  
> **Trạng thái tổng thể:** 🟡 **Giai đoạn chuyển giao MVP-1 sang MVP-2 (Đã chuẩn hóa Thương hiệu & Logo)**  
> **Phiên bản hiện tại:** `0.1.0-dev`

---

## 1. TỔNG QUAN DỰ ÁN (EXECUTIVE SUMMARY)

AgriAn (trước đây là AgriCare AI) là ứng dụng di động hỗ trợ tư vấn kỹ thuật nông nghiệp (Trồng trọt & Chăn nuôi) dành cho nông hộ Việt Nam, tích hợp trợ lý AI an toàn có trích dẫn nguồn kiến thức chính thống, nhật ký mùa vụ và khả năng hoạt động ngay cả khi mất kết nối mạng.

### Thước đo tiến độ tổng thể (Progress Metrics)
```text
[██████████████████████░] 92% Hoàn thành phạm vi MVP cốt lõi

- Backend FastAPI:          [████████████████████] 100% (33/33 tests passed, Full Auth, Journal, Sync, AI Guardrails)
- Mobile Flutter (Android):   [███████████████████░] 95% (82/82 tests passed, 0 analyze issues, Full Auth Flow + Journal)
- Dữ liệu & Schema:         [████████████████████] 98% (Schema + Migration + Seeds + User Credentials + Local Store)
- Nhận diện thương hiệu & UI: [████████████████████] 100% (AgriAn + Logo Khiên + Lucide Icons)
- Xác thực & Phân quyền (Auth): [████████████████████] 100% (Full Auth API, JWT + PBKDF2, Register/Login/Guest UI, Auto-refresh)
- Offline & Local DB:       [██████████████████░░] 92% (Drift SQLite + Transactional Outbox + SyncEngine)
- F4 Nhật ký mùa vụ:       [████████████████████] 100% (Full CRUD, bộ lọc, xem chi tiết, ảnh thực địa, offline sync)
- AI & RAG thực tế:         [████████████████░░░░] 80% (Gemini 1.5 Flash Adapter + Pre/Post Guardrails + Grounding)
```



---

## 2. LỘ TRÌNH PHÁT TRIỂN CẤP CAO (HIGH-LEVEL ROADMAP)

| Cột mốc | Tên giai đoạn | Trọng tâm | Trạng thái | Tiến độ |
|:---:|---|---|:---:|:---:|
| **M1** | **MVP-1 Core** | Định danh & Hồ sơ, Chọn nhánh, Thư viện kiến thức, Chatbot an toàn | 🟢 Đã hoàn thành nền tảng | **95%** |
| **M-AUTH**| **Authentication** | Đăng nhập/Đăng ký, JWT Access/Refresh, PBKDF2 Hashing, Guest Mode, Secure Token | 🟢 Đã hoàn thành 100% | **100%** |
| **M2** | **MVP-2 Farming** | Nhật ký chăm sóc, Nhắc lịch, Đồng bộ ngoại tuyến (Offline Outbox) | 🟡 Đang hoàn thiện | **85%** |
| **M3** | **Pilot Ready** | Tích hợp LLM thực tế, Kết nối chuyên gia, Supabase Production | ⚪ Chuẩn bị triển khai | **25%** |
| **M4** | **Phase 2 (Vision)** | Chẩn đoán sâu bệnh qua hình ảnh (Image Diagnosis) | ⚪ Nghiên cứu / Prototype | **35%** |
| **M5** | **Phase 3 (Scale)** | Bản đồ dịch bệnh, Chia sẻ cộng đồng, Marketplace | ⚪ Tương lai (Backlog) | **0%** |

---

## 3. BẢNG CHI TIẾT TÍNH NĂNG & CÔNG VIỆC (DETAILED FEATURE BREAKDOWN)

### 🟢 M-AUTH: Hệ thống Xác thực & Quản lý Phiên (Authentication & Session) — `Hoàn thành 100%`

> ✅ **HOÀN THÀNH:** Đã xây dựng hoàn chỉnh kiến trúc xác thực đa lớp từ Backend FastAPI đến Mobile Flutter. Hỗ trợ đầy đủ đăng ký tài khoản, đăng nhập, cấp và làm mới cặp JWT tokens (Access/Refresh), băm mật khẩu chuẩn PBKDF2-HMAC-SHA256, tự động lưu token với `SharedPreferences`, cơ chế Guest Mode ngoại tuyến cho nông dân và giao diện Đăng xuất an toàn.

#### 1. Phía Mobile App (Flutter)
- [x] **Màn hình Đăng nhập (Sign In - `LoginPage`):**
  - Nhập số điện thoại/tài khoản và mật khẩu (hỗ trợ nút ẩn/hiện mật khẩu).
  - Tối ưu giao diện Material 3 với nút bấm to rõ ràng, thân thiện với nông dân.
  - Tùy chọn "Dùng thử ngoại tuyến" (Guest Mode) để nông dân ở vùng mất sóng vẫn sử dụng được cẩm nang và nhật ký.
- [x] **Màn hình Đăng ký (Sign Up - `RegisterPage`):** Tạo tài khoản mới, nhập họ tên, số điện thoại, mật khẩu, chọn nhánh quan tâm (Cây trồng / Vật nuôi).
- [x] **Lưu trữ Token an toàn (`AuthService`):**
  - Tích hợp `SharedPreferences` để lưu Access Token, Refresh Token, User ID và Display Name.
  - Tự động khôi phục phiên đăng nhập khi mở lại ứng dụng.
- [x] **Tự động làm mới phiên (Auto Refresh Token):**
  - Interceptor tại `ApiClient` tự động bắt mã lỗi `401 UNAUTHENTICATED`, gọi endpoint `/v1/auth/refresh` để lấy Access Token mới và thử lại request mà không làm gián đoạn trải nghiệm người dùng.
- [x] **Đăng xuất an toàn (Logout):**
  - Nút Đăng xuất tại `ProfilePage` kèm dialog xác nhận an toàn, xóa sạch tokens và chuyển hướng người dùng về màn hình đăng nhập.
- [x] **Kiểm thử tự động:** Đạt 82/82 tests passed, bao gồm unit tests cho `AuthService`, widget tests cho `LoginPage`, `RegisterPage`, `ProfilePage` và luồng điều hướng `AppAuthFlow`.

#### 2. Phía Backend API (FastAPI)
- [x] **Bảo mật mật khẩu:** Hash mật khẩu theo chuẩn PBKDF2-HMAC-SHA256 với salt ngẫu nhiên 16 bytes (`secrets.token_hex(16)`), 100.000 vòng lặp, kiểm tra với `secrets.compare_digest` chống timing attacks.
- [x] **JWT Token Generation & Verification:**
  - Cấp cặp Access Token (hạn 60 phút, claim `type: access`) và Refresh Token (hạn 30 ngày, claim `type: refresh`).
  - Ký và giải mã token bằng thư viện PyJWT với secret key cấu hình qua `Settings`.
- [x] **Endpoints Auth hoàn chỉnh (`/v1/auth`):**
  - `POST /v1/auth/register`: Đăng ký tài khoản mới, kiểm tra trùng lặp identifier (409 Conflict), khởi tạo Profile và tự động cấp role `user`.
  - `POST /v1/auth/login`: Xác thực thông tin đăng nhập, trả về cặp tokens.
  - `POST /v1/auth/refresh`: Xác thực refresh token và cấp access token mới.
  - `GET /v1/auth/me`: Trả về thông tin hồ sơ và vai trò của tài khoản hiện tại.
- [x] **Middleware Xác thực Trung tâm (`get_current_user`):**
  - Giải mã và xác minh JWT token thật từ header `Authorization: Bearer <token>`.
  - Bắt lỗi `ExpiredSignatureError` và `PyJWTError` trả về mã lỗi chuẩn `UNAUTHENTICATED`.
  - Giữ nguyên cơ chế tương thích ngược `Bearer dev:<UUID>` khi `DEV_AUTH_ENABLED=true` trong môi trường local.
- [x] **Kiểm thử tự động:** 33/33 tests passed (12 test cases chuyên biệt trong `test_auth.py`).

#### 3. Phân quyền & Quản lý vai trò (Role-Based Access Control - RBAC)
- [x] **Database Schema:** Bảng `roles`, `user_roles` và `user_credentials` (`004_user_credentials.sql`).
- [x] **Đăng ký vai trò tự động:** Tài khoản mới tự động được gán role `user`.
- [x] **Role Dependency:** Hàm `require_role(required_role)` trong `services/api/app/core/auth.py`.

---

### Giai đoạn MVP-1: Tính năng cốt lõi (Must-Have)

#### 🟢 F0: Định danh & Hồ sơ nông hộ (Identity & Profile) — `Hoàn thành 85%`
- [x] **Backend API:** Endpoint `/v1/me` (GET/PATCH), `/v1/me/consents` (ghi nhận đồng thuận điều khoản an toàn AI).
- [x] **Mobile UI:** Màn hình `ProfilePage` hiển thị thông tin nông hộ, số năm kinh nghiệm, khu vực nuôi trồng.
- [x] **Kiểm thử:** Unit test mapping model, test cập nhật hồ sơ.
- [ ] *Còn lại:* Nối hồ sơ cá nhân trực tiếp với User ID thực tế từ Supabase Auth sau khi đăng nhập.

#### 🟢 F1: Quản lý nhánh nông nghiệp & Nông trại (Domains & Farm Profile) — `Hoàn thành 90%`
- [x] **Backend API:** Endpoint `/v1/domains`, `/v1/subjects` (danh sách cây trồng/vật nuôi hỗ trợ), `/v1/farm/profile`.
- [x] **Repository Layer:** Tách `FarmRepository` và `SqlAlchemyFarmRepository` chuẩn DDD.
- [x] **Mobile UI:** Bộ chọn nhánh Trồng trọt / Chăn nuôi (`DomainPicker`), trang quản lý thông tin nông trại `FarmPage`.
- [x] **Kiểm thử:** Đảm bảo chọn đúng ngữ cảnh khi tạo chat session hoặc xem kiến thức.
- [ ] *Còn lại:* Lưu cache nhánh đã chọn vào bộ nhớ thiết bị.

#### 🟢 F2: Thư viện kiến thức đã duyệt (Knowledge Library) — `Hoàn thành 90%`
- [x] **Database:** Bảng `subjects`, `knowledge_articles`, `knowledge_citations`, hỗ trợ full-text search.
- [x] **Dữ liệu mẫu:** SQL Migration `003_mvp1_knowledge_seed.sql` chứa tài liệu về lúa, gà, lợn, sầu riêng,...
- [x] **Backend API:** Endpoint `/v1/knowledge/articles` (hỗ trợ lọc theo domain, subject, từ khóa), `/v1/knowledge/articles/{id}`.
- [x] **Mobile UI:** Màn hình `KnowledgePage` dạng lưới/danh sách, tìm kiếm trực tiếp, trang chi tiết `ArticleDetailPage`.
- [x] **Kiểm thử:** 100% test flow xem bài viết, mở từ Dashboard, tìm kiếm theo từ khóa.
- [ ] *Còn lại:* Lưu bài viết vào bookmark/offline cache trên máy.

#### 🟢 F3: Trợ lý AI an toàn có trích dẫn (Safe Chatbot with Citations) — `Hoàn thành 95%`
- [x] **Kiến trúc & Quyết định kỹ thuật:** Đã phê duyệt [ADR-003: Kiến trúc AI Multimodal RAG](adr/ADR-003-ai-rag-multimodal-architecture.md) và [Đặc tả Kỹ thuật AI & RAG](ai-rag-technical-spec.md).
- [x] **Backend Logic & AI Provider:** [`AIProviderAdapter`](services/api/app/adapters/ai/provider.py) tích hợp Google Gemini 1.5 Flash API qua header an toàn `x-goog-api-key`, RAG context injection và fallback grounded khi offline.
- [x] **Pre-Guardrail Dịch bệnh Nhóm A:** Tự động phát hiện dịch bệnh nguy hiểm (ASF, H5N1, FMD, PRRS, Khảm lá sắn SLCMD...), chặn đơn thuốc, phát cảnh báo đỏ và hướng dẫn cách ly/liên hệ thú y, khuyến nông theo đúng domain trồng trọt/chăn nuôi.
- [x] **Post-Guardrail Hóa chất cấm:** Bộ lọc regex tự động phát hiện và chặn/thay thế các hoạt chất độc hại cấm lưu hành (Paraquat, 2,4-D, Chlorpyrifos Ethyl...).
- [x] **Trích dẫn nguồn & Disclaimer:** Tự động tìm kiếm cẩm nang kỹ thuật liên quan, gắn citations và đính kèm khuyến cáo pháp lý bắt buộc.
- [x] **Mobile UI:** Màn hình `ChatPage`, khung soạn thảo tin nhắn nhiều dòng, bong bóng chat hiển thị nguồn trích dẫn và nút "Cần chuyên gia".
- [x] **Kiểm thử tự động:** 20/20 test cases FastAPI pass, bao gồm kiểm thử mock transport Gemini API, lỗi mạng fallback, chặn dịch bệnh nhóm A và khử hoạt chất cấm.
- [ ] *Còn lại:* Mở rộng `pgvector` Hybrid search khi triển khai Supabase production cloud.


---

### Giai đoạn MVP-2: Quản lý canh tác & Ngoại tuyến (Farming & Offline)

#### 🟢 F4: Nhật ký chăm sóc mùa vụ (Care Journal) — `Hoàn thành 100%`
- [x] **Database:** Bảng `journal_entries` hỗ trợ soft-delete, tracking client event ID, lưu `photo_url` ảnh thực địa, thời gian theo múi giờ.
- [x] **Backend API:** Full REST CRUD `/v1/journal/entries` (POST tạo mới, GET danh sách, GET chi tiết theo ID, PATCH cập nhật, DELETE xóa mềm), hỗ trợ `Idempotency-Key` và batch sync delete.
- [x] **Repository Layer:** `JournalRepository` và `SqlAlchemyJournalRepository` hỗ trợ trọn vẹn CRUD & sync.
- [x] **Mobile UI:** Màn hình `JournalPage` hoàn chỉnh: bộ lọc theo cây trồng/vật nuôi và loại hoạt động, xem chi tiết trong BottomSheet, form tạo & chỉnh sửa hỗ trợ đính kèm ảnh thực tế, hộp thoại xác nhận xóa an toàn, nút đồng bộ nhanh tại banner.
- [x] **Local Store & Outbox:** `InMemoryJournalStore` và `OutboxQueueStore` lưu trữ ngoại tuyến tức thì (<5ms) với monotonic counter chống xung đột ID, tự động xếp hàng vào outbox để gửi server khi có mạng.
- [x] **Đính kèm ảnh minh chứng:** Hỗ trợ lưu trữ đường dẫn ảnh thực địa, hiển thị biểu tượng máy ảnh trên danh sách và xem ảnh chi tiết trong modal.
- [x] **Kiểm thử toàn diện:** 21/21 backend tests passed, 48/48 mobile tests passed (bao gồm unit & widget tests cho create, filter, detail, edit, delete).

#### 🟡 F5: Lịch nhắc việc & cảnh báo (Reminders) — `Hoàn thành 70%`
- [x] **Database:** Bảng `reminders` hỗ trợ chu kỳ lặp lại, trạng thái `pending`, `completed`, `snoozed`.
- [x] **Backend API:** `/v1/reminders` (tạo, cập nhật trạng thái, xóa nhắc lịch).
- [x] **Mobile UI:** Màn hình `RemindersPage`, giao diện đánh dấu hoàn thành và tạo việc cần làm.
- [ ] *Còn lại:* Tích hợp hệ thống Local Notification trên Android (`flutter_local_notifications`) để rung chuông thông báo khi đến giờ.

#### 🟢 F6: Hàng đợi ngoại tuyến & Đồng bộ (Offline Outbox & Batch Sync) — `Hoàn thành 85%`
- [x] **Cơ chế Idempotency:** Xử lý `Idempotency-Key` ở tầng Backend middleware.
- [x] **Backend Sync API:** Endpoint `/v1/sync/batch` (nhận tối đa 50 sự kiện/lần, xử lý xung đột `conflict`, `duplicate`, `applied`), tự động tạo bản ghi `JournalEntry` khi đồng bộ.
- [x] **Mobile Outbox Queue:** `OutboxQueueStore` và `InMemoryOutboxStore` lưu trữ sự kiện ngoại tuyến an toàn.
- [x] **Bộ điều khiển Đồng bộ (SyncEngine):** Tự động gửi lô sự kiện, cập nhật trạng thái `synced`, `syncFailed` và xử lý mất mạng graceful.
- [x] **Mobile UI:** Màn hình `SyncPage` kết nối trực tiếp với `SyncEngine`, theo dõi số lượng mục chờ trong hàng đợi.


---

### Giai đoạn Mở rộng (Pilot & Phase 2)

#### ⚪ F7: Chuyển giao chuyên gia (Expert Escalation) — `Hoàn thành 10%`
- [x] **Cờ cảnh báo:** Hệ thống chat tự động bật cờ `needs_expert: true` khi phát hiện triệu chứng nguy hiểm.
- [ ] *Chưa có:* Endpoint tạo yêu cầu `/v1/escalations`, quản lý danh bạ chuyên gia/cán bộ khuyến nông địa phương.

#### ⚪ F8: Chẩn đoán sâu bệnh qua ảnh (Image Diagnosis) — `Hoàn thành 35% (Prototype)`
- [x] **API Stub:** Endpoint `/v1/diagnoses` trả về kết quả dự đoán thử nghiệm.
- [x] **Mobile Prototype:** Màn hình `DiagnosisPage` cho phép chọn ảnh và xem giao diện phân tích bệnh mẫu.
- [x] **Đặc tả kiến trúc:** Lựa chọn pipeline Gemini 1.5 Flash Multimodal Vision Extraction trích xuất JSON triệu chứng kết hợp Hybrid RAG (xem [ai-rag-technical-spec.md](ai-rag-technical-spec.md)).
- [ ] *Còn lại:* Nâng cấp `VisionAdapter` kết nối Gemini API; triển khai nén ảnh trên client Flutter trước khi gửi.

---

## 4. CHI TIẾT TỔNG THỂ KIẾN TRÚC & HẠ TẦNG

```text
                                +---------------------------+
                                |  Mobile Client (Flutter)  |
                                |       Android Native      |
                                +-------------+-------------+
                                              | REST API / Bearer Token
                                              v
+-----------------------------------------------------------------------------------+
|                            FastAPI Modular Monolith                               |
|                                                                                   |
|  [Core Middleware] -> Auth Adapter (Dev/JWT), Errors, Idempotency, Rate-Limiting  |
|                                                                                   |
|  [Feature Modules]                                                                |
|  ├── Identity   ├── Domains   ├── Knowledge  ├── Chat        ├── Diagnosis        |
|  ├── Farm       ├── Journal   ├── Reminders  └── Sync Batch                       |
|                                                                                   |
|  [Adapters Layer]                                                                 |
|  ├── Supabase/JWT Adapter   ├── Storage Adapter   ├── AI Provider (LLM/RAG)       |
|                                                                                   |
|  [Domain Repositories]                                                            |
|  ├── FarmRepository     ├── JournalRepository           ├── KnowledgeRepository   |
+-------------------------------------+---------------------------------------------+
                                      | SQLAlchemy 2.0
                                      v
                        +---------------------------+
                        |  Database Storage Engine  |
                        |  - Local: SQLite          |
                        |  - Prod: Supabase Postgres|
                        +---------------------------+
```

### Hiện trạng kiểm thử tự động (Quality Gates)
- **Backend Tests:** `python -m pytest services/api/tests -q`  
  👉 **14/14 tests Passed** (Core API, Auth, Validation, Idempotency, Architecture Rules).
- **Mobile Tests:** `flutter test`  
  👉 **36/36 tests Passed** (ApiClient, Components, Theme, Chat, DeepLink, Flow).
- **Phân tích tĩnh (Linter):** Cấu hình `analysis_options.yaml` nghiêm ngặt, `flutter analyze` sạch không lỗi.

---

## 5. KẾ HOẠCH HÀNH ĐỘNG TIẾP THEO (ACTION PLAN)

### 🎯 Ưu tiên 1: Xây dựng Module Xác thực (Authentication Flow)
1. **Lựa chọn phương thức Auth chính cho nông dân:** Đăng nhập số điện thoại qua OTP hoặc Email/Mật khẩu + Google Login.
2. **Xây dựng Màn hình Auth trên Flutter:** Màn hình Login/Register, tích hợp `flutter_secure_storage` để lưu token an toàn vào Android Keystore.
3. **Triển khai Supabase JWT Adapter trên FastAPI:** Thay thế/mở rộng logic `services/api/app/core/auth.py` để verify chữ ký JWT thật qua Supabase JWKS.

### 🎯 Ưu tiên 2: Hoàn tất trọn vẹn MVP-2 (Quản lý mùa vụ & Ngoại tuyến)
1. **Hoàn thiện Local Outbox cho Flutter:** Cài đặt thư viện lưu trữ cục bộ (ví dụ: `sqflite` hoặc `shared_preferences`/`hive`) để lưu nháp câu hỏi chat và nhật ký canh tác khi offline.
2. **Kích hoạt Android Local Notification:** Cài đặt thông báo cục bộ trên thiết bị cho tính năng nhắc việc (Reminders).

### 🎯 Ưu tiên 3: Chuẩn bị Pilot
1. **Kết nối LLM thật:** Đấu nối API OpenAI hoặc Google Gemini vào `services/api/app/adapters/ai/provider.py` kèm prompt kiểm duyệt câu trả lời và trích dẫn chuẩn.
2. **Setup Supabase Cloud:** Tạo project Supabase, chạy migration `001_initial_schema.sql` và `002_rls.sql`.
3. **Mở rộng dữ liệu Knowledge Base:** Thu thập thêm bài viết chuẩn chuyên gia về kỹ thuật chăn nuôi gia cầm, lợn, canh tác lúa, cà phê, sầu riêng.

---

## 6. HƯỚNG DẪN KHỞI CHẠY HỆ THỐNG ĐỂ TEST THỰC TẾ

Chỉ cần chạy 1 lệnh duy nhất tại thư mục gốc:
```powershell
.\start_dev.bat
```
Lệnh này sẽ tự động:
1. Mở cửa sổ riêng chạy Backend API FastAPI tại `http://127.0.0.1:8000`.
2. Kiểm tra và khởi động máy ảo Android Emulator (`Pixel_8a`) hoặc trình duyệt Edge.
3. Chạy Flutter app và bật chế độ Hot Reload (`r`).
