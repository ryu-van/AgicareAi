# AgriCare AI

Ứng dụng Android tư vấn chăm sóc cây trồng và vật nuôi cho nông hộ Việt Nam.

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

## Chạy API local

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

- [Requirements](docs/requirements.md)
- [Features](docs/features.md)
- [API contract](docs/api-contract.md)
- [Architecture](docs/architecture.md)
- [Project structure](docs/project-structure.md)
- [Design system](design-system/agricare-ai/MASTER.md)
