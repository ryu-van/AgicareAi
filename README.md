# AgriAn (AgriCare AI)

Ứng dụng Android tư vấn kỹ thuật nông nghiệp thông minh (Trồng trọt & Chăn nuôi) cho nông hộ Việt Nam.
*Khẩu hiệu: "Vụ mùa an tâm, nông gia thịnh vượng"*

Đây là MVP local/demo: dữ liệu kiến thức là fixture, API dùng dev auth khi
chạy local và chưa phải bản production.

## Stack

- Mobile Android: Flutter 3.44.7 / Dart 3.12.2 tại `apps/mobile_flutter`
- API: FastAPI, Python 3.12, Pydantic Settings, SQLAlchemy
- Database local: SQLite
- Database production dự kiến: Supabase PostgreSQL

## Yêu cầu

- Flutter 3.44.7 và Dart 3.12.2
- Python 3.12+
- Android Studio và Android SDK

## Khởi động phát triển (1 lệnh duy nhất)

Chạy file script khởi động toàn bộ:

```powershell
.\start_dev.bat
# hoặc
npm run dev
```

Script sẽ tự động:
1. Khởi động Backend API (`FastAPI`) trong một cửa sổ riêng.
2. Khởi động máy ảo Android (`Pixel_8a`) hoặc trình duyệt Edge.
3. Chạy ứng dụng Flutter với chế độ Hot Reload (`r` để tải lại tức thì).

## Chạy API local thủ công

```powershell
Copy-Item .env.example .env
python -m venv services/api/.venv
.\services\api\.venv\Scripts\Activate.ps1
python -m pip install -r services/api/requirements.txt
python -m uvicorn services.api.app.main:app --reload
```

Kiểm tra: `Invoke-WebRequest http://127.0.0.1:8000/health`.

## Chạy Android app

```powershell
cd apps/mobile_flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEV_AUTH_ENABLED=true
```

`10.0.2.2` là địa chỉ máy host từ Android emulator. Với điện thoại thật, thay
bằng địa chỉ IP LAN của máy chạy API.

Build APK preview:

```powershell
.\tool\build_flutter.ps1 -Flavor preview -Mode debug -ApiBaseUrl https://api.example.com
```

## Kiểm tra

```powershell
cd apps/mobile_flutter
flutter analyze
flutter test
cd ../..
python -m pytest services/api/tests -q
```

## Tài liệu

- [Tiến trình dự án (Progress Tracker)](docs/project-progress.md)
- [Quy chuẩn thương hiệu & Logo (Brand Guidelines)](docs/brand-guidelines.md)
- [Requirements](docs/requirements.md)
- [Features](docs/features.md)
- [API contract](docs/api-contract.md)
- [Architecture](docs/architecture.md)
- [Project structure](docs/project-structure.md)
- [Design system](design-system/agricare-ai/MASTER.md)
