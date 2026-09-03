# AgriCare AI

Ứng dụng Flutter tư vấn chăm sóc cây trồng và vật nuôi cho nông hộ Việt Nam.

Đây là MVP local/demo. Dữ liệu knowledge hiện là fixture, API dùng dev auth khi chạy local, và chưa phải bản production.

## Stack

- Mobile: Flutter 3.44.7/Dart 3.12.2 tại `apps/mobile_flutter`
- API: FastAPI, Python 3.12, Pydantic Settings, SQLAlchemy
- Database local mặc định: SQLite
- Database production dự kiến: Supabase PostgreSQL

## Yêu cầu

- Flutter 3.44.7 và Dart 3.12.2
- Python 3.12+
- Android Studio + Android SDK nếu chạy Android local
- macOS + Xcode nếu chạy iOS local

## 1. Chạy API local

```powershell
Copy-Item .env.example .env
python -m venv services/api/.venv
.\services\api\.venv\Scripts\Activate.ps1
python -m pip install -r services/api/requirements.txt
python -m uvicorn services.api.app.main:app --reload
```

Kiểm tra: `Invoke-WebRequest http://127.0.0.1:8000/health`.

## 2. Chạy Flutter

```powershell
cd apps/mobile_flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEV_AUTH_ENABLED=true
```

Build APK preview:

```powershell
.\tool\build_flutter.ps1 -Flavor preview -Mode debug -ApiBaseUrl https://api.example.com
```

Build iOS local cần macOS/Xcode. Production build cần signing secrets; xem [Flutter release runbook](docs/flutter-release-runbook.md).

## 3. Kiểm tra

```powershell
cd apps/mobile_flutter
flutter analyze
flutter test
cd ../..
python -m pytest services/api/tests -q
```

## Tài liệu

- [Requirements](docs/requirements.md)
- [Features](docs/features.md)
- [API contract](docs/api-contract.md)
- [Architecture](docs/architecture.md)
- [Design system](design-system/agricare-ai/MASTER.md)
- [Flutter migration checklist](docs/flutter-migration-checklist.md)
- [Flutter release runbook](docs/flutter-release-runbook.md)
- [Flutter release readiness](docs/flutter-release-readiness.md)
- [Flutter accessibility audit](docs/flutter-accessibility-audit.md)
