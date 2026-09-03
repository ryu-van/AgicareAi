# AgriCare AI — Flutter client

Flutter/Dart client đang được migrate song song với `apps/mobile` (Expo/React Native). Backend FastAPI và API contract giữ nguyên trong giai đoạn migration.

## Yêu cầu

- Flutter stable 3.44.7
- Dart 3.12.2 (đi kèm Flutter)
- Android Studio + Android SDK cho Android
- macOS + Xcode là bắt buộc để build/test iOS

## Chạy local

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

URL API theo môi trường:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator/web: `http://127.0.0.1:8000`
- Thiết bị thật: `http://<LAN_IP_cua_may_dev>:8000`

Có thể override user demo bằng `--dart-define=DEV_USER_ID=<uuid>`. Không đưa API key hoặc secret vào bundle Flutter.

Dev auth chỉ được bật cho `dev`/`preview`. Build `production` qua `tool/build_flutter.ps1` tự truyền `--dart-define=DEV_AUTH_ENABLED=false`; production vẫn cần tích hợp auth thật trước khi phát hành.

## Kiểm tra và build

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=https://api.example.com

# Hoặc chạy toàn bộ gate + build theo flavor
./tool/build_flutter.ps1 -Flavor dev -Mode debug -ApiBaseUrl http://10.0.2.2:8000
# Máy/CI ít dung lượng có thể build một ABI cụ thể
./tool/build_flutter.ps1 -Flavor preview -Mode debug -TargetPlatform android-arm64 -ApiBaseUrl https://api.example.com
```

Trước khi build release cần cấu hình signing, flavor/API URL production và kiểm tra `flutter doctor`.

Nếu Android emulator báo thiếu `kernel-ranchu`, hãy cài lại đúng system image khớp AVD bằng Android Studio/SDK Manager, đặt `ANDROID_SDK_ROOT` trỏ tới Android SDK rồi khởi động lại AVD. Không đánh dấu integration test pass chỉ vì AVD đã xuất hiện trong `flutter emulators`; phải xác nhận `flutter devices` nhìn thấy emulator đang boot hoàn tất.

Trên Windows PowerShell, có thể cấu hình phiên hiện tại trước khi chạy SDK Manager:

```powershell
$env:ANDROID_SDK_ROOT = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
$env:JAVA_HOME = "D:\Android\jbr"
& "$env:ANDROID_SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" --install "system-images;android-35;google_apis_playstore;x86_64"
```

Chạy `powershell -ExecutionPolicy Bypass -File tool/check_android_environment.ps1` để kiểm tra nhanh SDK, JDK, AVD và file `kernel-ranchu` trước integration test.

`dev`, `preview` và `production` là Android flavors. Với web/CI, dùng `--dart-define=APP_FLAVOR=production` (không dùng tên reserved `FLUTTER_APP_FLAVOR`). Production release phải truyền API URL HTTPS rõ ràng và tự tắt demo auth; signing thật dùng `android/key.properties` tạo từ file mẫu và không được commit.

Deep links dùng scheme `agricare-ai`: `agricare-ai://chat` và `agricare-ai://knowledge/<articleId>`. Android đã đăng ký intent filter và iOS đã đăng ký URL scheme; vẫn cần xác nhận launch từ thiết bị thật trước release.

## Cấu trúc hiện tại

- `lib/app.dart`: app shell và bottom navigation
- `lib/theme/`: Material 3 theme và AgriCare design tokens
- `lib/config/`: compile-time environment config
- `lib/data/`: HTTP client và model mapping
- `lib/features/home/`: Home vertical slice đầu tiên

Knowledge detail, Chat, Profile đầy đủ và release pipeline vẫn nằm trong checklist migration.

Architecture decisions: `../../docs/flutter-architecture.md`.

CI chạy format, analyze, unit/widget tests và Android dev-flavor debug build. Production signing/TestFlight là protected release steps.
