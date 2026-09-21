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
[████████████████░░░░░░░░] 68% Hoàn thành phạm vi MVP cốt lõi

- Backend FastAPI:          [██████████████████░░] 90% (14/14 tests passed, GET & Batch Sync Journal)
- Mobile Flutter (Android):   [█████████████████░░░] 85% (44/44 tests passed, 0 analyze issues)
- Dữ liệu & Schema:         [████████████████░░░░] 85% (Schema + Migration + Seeds + Local Store)
- Nhận diện thương hiệu & UI: [████████████████████] 100% (AgriAn + Logo Khiên + Lucide Icons)
- Xác thực & Phân quyền (Auth): [███░░░░░░░░░░░░░░░░░] 15% (Chỉ có Dev Auth cục bộ, CHƯA có Login/Register/JWT)
- Offline & Local DB:       [█████████████████░░░] 85% (Local Store + Transactional Outbox + SyncEngine)
- AI & RAG thực tế:         [██████░░░░░░░░░░░░░░] 30% (Rule-based & fixture search xong, chưa gắn LLM)
```


---

## 2. LỘ TRÌNH PHÁT TRIỂN CẤP CAO (HIGH-LEVEL ROADMAP)

| Cột mốc | Tên giai đoạn | Trọng tâm | Trạng thái | Tiến độ |
|:---:|---|---|:---:|:---:|
| **M1** | **MVP-1 Core** | Định danh & Hồ sơ, Chọn nhánh, Thư viện kiến thức, Chatbot an toàn | 🟢 Đã hoàn thành nền tảng | **90%** |
| **M-AUTH**| **Authentication** | Đăng nhập/Đăng ký, OTP/Mật khẩu, JWT Supabase, Secure Storage, Phân quyền | 🔴 Khoảng trống lớn cần làm | **15%** |
| **M2** | **MVP-2 Farming** | Nhật ký chăm sóc, Nhắc lịch, Đồng bộ ngoại tuyến (Offline Outbox) | 🟡 Đang hoàn thiện | **65%** |
| **M3** | **Pilot Ready** | Tích hợp LLM thực tế, Kết nối chuyên gia, Supabase Production | ⚪ Chuẩn bị triển khai | **20%** |
| **M4** | **Phase 2 (Vision)** | Chẩn đoán sâu bệnh qua hình ảnh (Image Diagnosis) | ⚪ Nghiên cứu / Prototype | **15%** |
| **M5** | **Phase 3 (Scale)** | Bản đồ dịch bệnh, Chia sẻ cộng đồng, Marketplace | ⚪ Tương lai (Backlog) | **0%** |

---

## 3. BẢNG CHI TIẾT TÍNH NĂNG & CÔNG VIỆC (DETAILED FEATURE BREAKDOWN)

### 🔴 M-AUTH: Hệ thống Xác thực & Quản lý Phiên (Authentication & Session) — `Hoàn thành 15%`

> ⚠️ **LƯU Ý:** Hiện tại dự án đang sử dụng cơ chế **Dev Auth giả lập** (`Bearer dev:<UUID>`) để phục vụ kiểm thử cục bộ. Toàn bộ quy trình đăng nhập, đăng ký và bảo mật phiên thật sự **chưa được xây dựng** và cần triển khai trước khi ra mắt công chúng.

#### 1. Phía Mobile App (Flutter)
- [ ] **Màn hình Chào đón / Onboarding:** Giới thiệu ngắn gọn các tính năng, điều khoản sử dụng và nút bắt đầu.
- [ ] **Màn hình Đăng nhập (Sign In):**
  - Nhập số điện thoại (hoặc Email) & Mật khẩu.
  - Hoặc gửi mã OTP qua SMS/Zalo (phù hợp với nông dân lớn tuổi).
  - Tùy chọn đăng nhập nhanh với Google (Google Sign-In).
- [ ] **Màn hình Đăng ký (Sign Up):** Tạo tài khoản mới, xác thực số điện thoại/email, nhập thông tin cơ bản.
- [ ] **Màn hình Quên mật khẩu (Forgot Password):** Gửi mã OTP xác thực và đặt lại mật khẩu mới.
- [ ] **Lưu trữ Token an toàn (Secure Storage):**
  - Tích hợp package `flutter_secure_storage` để lưu Access Token và Refresh Token vào Android Keystore mã hóa phần cứng (thay vì SharedPreferences thông thường).
- [ ] **Tự động làm mới phiên (Auto Refresh Token):**
  - Interceptor tại `ApiClient` tự động bắt mã lỗi `401 UNAUTHENTICATED`, gọi endpoint refresh token để lấy Access Token mới mà không làm ngắt quãng trải nghiệm người dùng.
- [ ] **Đăng xuất an toàn (Logout):**
  - Xóa sạch token, xóa cache cục bộ và chuyển hướng người dùng về màn hình đăng nhập.

#### 2. Phía Backend API (FastAPI)
- [x] **Dev Auth Handler:** Nhận dạng token dạng `dev:<UUID>` chỉ hoạt động khi biến `APP_ENV=local` và `DEV_AUTH_ENABLED=true`.
- [ ] **Supabase Auth Adapter (Production Auth):**
  - Xác thực chữ ký token JWT thông qua Public JWKS (JSON Web Key Set) từ Supabase Auth.
  - Kiểm tra tính hợp lệ: hạn sử dụng (`exp`), đơn vị cấp phát (`iss`), đối tượng nhận (`aud`).
  - Trích xuất định danh người dùng chuẩn (`sub` -> `user_id`).
- [ ] **Cơ chế Thu hồi & Hết hạn token (Token Revocation / Expiry):**
  - Trả về mã lỗi chuẩn `UNAUTHENTICATED` kèm yêu cầu làm mới phiên khi access token hết hạn (thường sau 1 giờ).
- [ ] **Bảo mật Endpoint & Rate Limiting cho Auth:**
  - Giới hạn số lần thử đăng nhập/yêu cầu gửi OTP để chống tấn công brute-force.

#### 3. Phân quyền & Quản lý vai trò (Role-Based Access Control - RBAC)
- [x] **Database Schema:** Đã tạo bảng `roles` và `user_roles` trong migration `001_initial_schema.sql`.
- [x] **Role Dependency:** Hàm `require_role(required_role)` trong `services/api/app/core/auth.py`.
- [ ] **Đăng ký vai trò tự động:** Khi tài khoản mới đăng ký, tự động gán role `user`.
- [ ] **Gán quyền chuyên gia / quản trị:** Cơ chế nâng quyền cho cán bộ khuyến nông (`expert`), người duyệt nội dung (`editor`), ban quản trị (`admin`).
- [ ] **Chính sách Row-Level Security (RLS):** Kích hoạt RLS trên PostgreSQL Supabase (`002_rls.sql`) để ngăn người dùng đọc chéo dữ liệu của nhau ở tầng database.

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

#### 🟡 F3: Trợ lý AI an toàn có trích dẫn (Safe Chatbot with Citations) — `Hoàn thành 85%`
- [x] **Kiến trúc & Quyết định kỹ thuật:** Đã phê duyệt [ADR-003: Kiến trúc AI Multimodal RAG](adr/ADR-003-ai-rag-multimodal-architecture.md) và [Đặc tả Kỹ thuật AI & RAG](ai-rag-technical-spec.md) (Gemini 1.5 Flash + pgvector Hybrid Search + 3-tier Safety Guardrails).
- [x] **Backend Logic:** Endpoint `/v1/chat/sessions`, `/v1/chat/sessions/{id}/messages`.
- [x] **Cơ chế an toàn (Safety Gate):** Phân cấp độ an toàn `normal` / `caution` / `urgent` dựa trên từ khóa nguy cấp (dịch bệnh, chết hàng loạt, thuốc độc hại).
- [x] **Trích dẫn nguồn:** Tự động tìm kiếm bài viết kiến thức liên quan và gắn `citations` vào câu trả lời.
- [x] **Mobile UI:** Màn hình `ChatPage`, khung soạn thảo tin nhắn nhiều dòng, bong bóng chat hiển thị nguồn trích dẫn và nút "Cần chuyên gia".
- [x] **Kiểm thử:** Test phân loại an toàn, test retry khi mạng chậm, test deep link mở chat session.
- [ ] *Còn lại:* Đấu nối LLM Provider thực tế (Gemini 1.5 Flash API) thông qua `AIProviderAdapter` và `RAGAdapter` (kết nối pgvector) theo đặc tả kỹ thuật.

---

### Giai đoạn MVP-2: Quản lý canh tác & Ngoại tuyến (Farming & Offline)

#### 🟢 F4: Nhật ký chăm sóc mùa vụ (Care Journal) — `Hoàn thành 85%`
- [x] **Database:** Bảng `journal_entries` hỗ trợ soft-delete, tracking client event ID, thời gian theo múi giờ.
- [x] **Backend API:** `/v1/journal/entries` (CRUD: POST tạo mới và GET lấy danh sách), hỗ trợ `Idempotency-Key` chống tạo lặp.
- [x] **Repository Layer:** `JournalRepository` và `SqlAlchemyJournalRepository`.
- [x] **Mobile UI:** Màn hình `JournalPage`, hiển thị dòng thời gian sự kiện nông nghiệp (bón phân, tiêm phòng, tưới tiêu, ghi nhận sâu bệnh), form nhập nhật ký ngoại tuyến với BottomSheet.
- [x] **Local Store:** `InMemoryJournalStore` / Local Data Source lưu trữ nhật ký ngay cả khi mất mạng.
- [ ] *Còn lại:* Tích hợp đính kèm ảnh chụp thực tế vào nhật ký.

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
