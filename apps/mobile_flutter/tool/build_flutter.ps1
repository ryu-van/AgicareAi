param(
  [ValidateSet('dev', 'preview', 'production')]
  [string]$Flavor = 'dev',
  [ValidateSet('debug', 'profile', 'release')]
  [string]$Mode = 'debug',
  [string]$ApiBaseUrl = '',
  [ValidateSet('', 'android-arm', 'android-arm64', 'android-x64')]
  [string]$TargetPlatform = ''
)

$ErrorActionPreference = 'Stop'
$flutterArgs = @('--flavor', $Flavor)
if ($ApiBaseUrl -ne '') { $flutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl" }
if ($TargetPlatform -ne '') { $flutterArgs += "--target-platform=$TargetPlatform" }
$devAuth = if ($Flavor -eq 'production') { 'false' } else { 'true' }
$flutterArgs += "--dart-define=DEV_AUTH_ENABLED=$devAuth"

flutter pub get
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test

if ($Mode -eq 'release' -and $Flavor -eq 'production' -and $ApiBaseUrl -notmatch '^https://') {
  throw 'Production release requires an explicit HTTPS API_BASE_URL.'
}
if ($Mode -eq 'release' -and $Flavor -eq 'production' -and -not (Test-Path 'android/key.properties')) {
  throw 'Production release requires android/key.properties created from android/key.properties.example.'
}

flutter build apk --$Mode @flutterArgs
