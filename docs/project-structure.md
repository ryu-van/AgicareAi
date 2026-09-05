# Cấu trúc source code AgriCare AI

Tài liệu này là bản đồ để đọc source code. Repository hiện chỉ hỗ trợ ứng dụng
Android; không có mã nguồn web, iOS hay desktop.

```text
agricare-ai/
├── apps/
│   └── mobile_flutter/             # Android app Flutter
│       ├── android/                # Native Android, Gradle, manifest, icon
│       ├── lib/                    # Source Dart chính
│       │   ├── main.dart           # Điểm khởi động Flutter
│       │   ├── app.dart            # App shell, route, bottom navigation
│       │   ├── config/             # API URL, flavor, dev auth
│       │   ├── core/               # Log client
│       │   ├── data/               # HTTP API client và model Dart
│       │   ├── features/           # Home, chat, knowledge, profile
│       │   ├── theme/              # Màu sắc, spacing, Material theme
│       │   └── widgets/            # Component dùng lại và domain picker
│       ├── test/                   # Unit và widget tests
│       ├── integration_test/       # Luồng test Android emulator
│       ├── tool/                   # Build, release, Android environment checks
│       ├── pubspec.yaml            # Flutter package và dependency
│       └── README.md               # Cách chạy Android app
├── services/
│   └── api/                        # FastAPI backend
│       ├── app/
│       │   ├── main.py             # Tạo FastAPI app và đăng ký router
│       │   ├── core/               # Config, auth, lỗi, DB, rate limit
│       │   ├── db/                 # SQLAlchemy model
│       │   └── modules/            # Từng chức năng API
│       │       ├── domains/        # Danh mục cây trồng/vật nuôi
│       │       ├── identity/       # Hồ sơ người dùng
│       │       ├── knowledge/      # Bài kiến thức
│       │       ├── chat/           # Chat, citation và safety response
│       │       ├── journal/        # Nhật ký chăm sóc (API nền tảng)
│       │       └── sync/           # Đồng bộ và idempotency
│       ├── db/migrations/          # SQL schema và seed local
│       ├── tests/                  # API tests
│       ├── requirements.txt        # Python dependency
│       └── README.md               # Cách chạy backend
├── packages/
│   └── contracts/                  # OpenAPI contract dùng chung
├── design-system/
│   └── agricare-ai/MASTER.md       # Quy tắc UI/UX và design tokens
├── docs/                           # Requirements, kiến trúc, API và ADR
├── .github/workflows/flutter.yml   # CI Android + API
├── .env.example                    # Mẫu biến môi trường, không chứa secret
└── README.md                       # Hướng dẫn bắt đầu ở cấp dự án
```

## Đọc source theo thứ tự

1. Đọc [README ở root](../README.md) để biết cách chạy API và Android app.
2. Đọc [app.dart](../apps/mobile_flutter/lib/app.dart): cấu trúc màn hình,
   điều hướng, deep link và điểm chọn ngữ cảnh chat.
3. Đọc các màn hình trong `apps/mobile_flutter/lib/features/`:
   `home` → `knowledge` → `chat` → `profile`.
4. Đọc `data/api_client.dart` để hiểu app gọi endpoint nào và model dữ liệu
   trên client.
5. Đọc `services/api/app/main.py`, sau đó đi vào từng module theo thứ tự:
   `router.py` → `schemas.py` → `service.py`.
6. Đọc `services/api/app/db/models.py` và `services/api/db/migrations/` khi
   cần hiểu dữ liệu và schema.
7. Đọc test cùng tên trước khi thay đổi hành vi:
   `apps/mobile_flutter/test/` cho mobile và `services/api/tests/` cho API.

## Luồng chính hiện tại

```text
Android app
  main.dart → app.dart → feature screen
                       → ApiClient
                       → FastAPI router
                       → service
                       → fixture/local database
```

## Lệnh kiểm tra

```powershell
# Android app
cd apps/mobile_flutter
flutter analyze
flutter test

# API, chạy từ repository root
python -m pytest services/api/tests -q
```

## Quy ước khi thêm code

- Thêm màn hình vào `lib/features/<feature>/`.
- Chỉ đặt request HTTP và mapping dữ liệu trong `lib/data/api_client.dart`.
- Thêm endpoint trong module FastAPI tương ứng, không đặt business logic vào
  `main.py`.
- Thêm test cùng thay đổi ở `test/` hoặc `services/api/tests/`.
- Cập nhật tài liệu này khi thêm package, service hoặc nền tảng mới.
