$ErrorActionPreference = 'Stop'

if (-not $env:API_BASE_URL -or $env:API_BASE_URL -notmatch '^https://') {
  throw 'Set API_BASE_URL=https://... before production performance measurement.'
}

$started = Get-Date
flutter build apk --release --flavor production --dart-define="API_BASE_URL=$env:API_BASE_URL" --dart-define=DEV_AUTH_ENABLED=false
$elapsed = ((Get-Date) - $started).TotalSeconds
$artifact = Resolve-Path 'build/app/outputs/flutter-apk/app-production-release.apk' -ErrorAction SilentlyContinue
if (-not $artifact) { throw 'Expected production APK was not generated.' }

$sizeMb = [math]::Round((Get-Item $artifact).Length / 1MB, 2)
Write-Host "Build seconds: $([math]::Round($elapsed, 2))"
Write-Host "APK size MB: $sizeMb"
Write-Host "Artifact: $artifact"
