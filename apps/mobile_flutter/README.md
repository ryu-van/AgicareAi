# AgriCare AI Android client

Flutter/Dart client cho ứng dụng Android AgriCare AI. Backend FastAPI và API
contract nằm ở thư mục gốc của repository.

## Yêu cầu

- Flutter stable 3.44.7
- Android Studio, Android SDK và một Android emulator hoặc thiết bị thật

## Chạy local

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEV_AUTH_ENABLED=true
```

Sử dụng `10.0.2.2` khi API chạy trên máy host và app chạy trong Android
emulator. Với thiết bị thật, dùng `http://<LAN_IP>:8000`.

## Kiểm tra và build

```powershell
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=API_BASE_URL=https://api.example.com
```

Build theo flavor:

```powershell
.\tool\build_flutter.ps1 -Flavor dev -Mode debug -ApiBaseUrl http://10.0.2.2:8000
.\tool\build_flutter.ps1 -Flavor preview -Mode debug -TargetPlatform android-arm64 -ApiBaseUrl https://api.example.com
```

Production yêu cầu API URL HTTPS, Android keystore/signing và tắt dev auth.

## Cấu trúc

- `lib/app.dart`: app shell và điều hướng
- `lib/theme/`: Material 3 theme và design tokens
- `lib/config/`: cấu hình compile-time
- `lib/data/`: HTTP client và model mapping
- `lib/features/`: các màn hình nghiệp vụ

CI chạy format, analyze, unit/widget tests, Android APK debug và Android
emulator integration test.
