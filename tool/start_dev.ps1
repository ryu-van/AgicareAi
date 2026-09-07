param(
  [ValidateSet('emulator', 'web', 'menu')]
  [string]$Target = 'emulator'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Get-Item $PSScriptRoot).Parent.FullName

# Ensure Environment Variables
$env:JAVA_HOME = "D:\Android\jbr"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\Sdk"
$env:ANDROID_AVD_HOME = "D:\Android\.android\avd"

$pathsToAdd = @(
  "D:\Dev\flutter\bin",
  "D:\Android\jbr\bin",
  "D:\Android\Sdk\platform-tools",
  "D:\Android\Sdk\emulator",
  "D:\Android\Sdk\cmdline-tools\latest\bin"
)
foreach ($p in $pathsToAdd) {
  if ($env:PATH -notlike "*$p*") {
    $env:PATH = "$p;$env:PATH"
  }
}

Write-Host "==========================================" -ForegroundColor Green
Write-Host "       AgriCare AI - Dev Starter          " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 1. Start Backend in separate window
Write-Host "`n[1/3] Khoi dong Backend API (FastAPI)..." -ForegroundColor Cyan
$pythonExe = Join-Path $repoRoot "services\api\.venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
  $pythonExe = "python"
}

# Check if port 8000 is already active
$portActive = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if (-not $portActive) {
  Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$repoRoot'; `$host.UI.RawUI.WindowTitle = 'AgriCare AI - Backend API'; & '$pythonExe' -m uvicorn services.api.app.main:app --reload --host 0.0.0.0 --port 8000"
  Write-Host "  -> Backend da duoc mo trong mot cua so rieng tai http://127.0.0.1:8000" -ForegroundColor Green
} else {
  Write-Host "  -> Backend da dang chay san tren cong 8000!" -ForegroundColor Yellow
}

# Target selection if menu
if ($Target -eq 'menu') {
  Write-Host "`nChon moi truong hien thi mobile:" -ForegroundColor Yellow
  Write-Host "  1. Android Emulator (May ao Pixel_8a - Day du tinh nang native)" -ForegroundColor White
  Write-Host "  2. Trinh duyet Edge (Web Mobile View - Khoi dong tuc thi, sieu nhe)" -ForegroundColor White
  $choice = Read-Host "`nNhap lua chon cua ban (1 hoac 2, mac dinh la 1)"
  if ($choice -eq '2') {
    $Target = 'web'
  } else {
    $Target = 'emulator'
  }
}

if ($Target -eq 'web') {
  Write-Host "`n[2/3] Chuan bi trinh duyet Edge..." -ForegroundColor Cyan
  Write-Host "[3/3] Khoi chay Flutter tren Edge..." -ForegroundColor Cyan
  Write-Host "`n========================================================" -ForegroundColor Magenta
  Write-Host "  Mẹo: Nhan F12 -> Ctrl+Shift+M de bat khung dien thoai!" -ForegroundColor Magenta
  Write-Host "  Nhan 'r' de Hot Reload, 'R' de Hot Restart, 'q' de thoat." -ForegroundColor Magenta
  Write-Host "========================================================`n" -ForegroundColor Magenta
  Set-Location (Join-Path $repoRoot "apps\mobile_flutter")
  & flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=DEV_AUTH_ENABLED=true
} else {
  Write-Host "`n[2/3] Kiem tra may ao Android (Pixel_8a)..." -ForegroundColor Cyan
  $adbExe = "D:\Android\Sdk\platform-tools\adb.exe"
  $devices = & $adbExe devices | Where-Object { $_ -match "emulator-\d+\s+device" }
  if (-not $devices) {
    Write-Host "  -> Dang bat may ao Pixel_8a..." -ForegroundColor Gray
    Remove-Item "$env:ANDROID_AVD_HOME\Pixel_8a.avd\*.lock" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath "D:\Android\Sdk\emulator\emulator.exe" -ArgumentList "-avd", "Pixel_8a"
    Write-Host "  -> Cho may ao khoi dong xong..." -ForegroundColor Gray
    & $adbExe wait-for-device
    
    # Wait for boot completion
    $bootCompleted = $false
    $timeout = 60
    $elapsed = 0
    while (-not $bootCompleted -and $elapsed -lt $timeout) {
      Start-Sleep -Seconds 2
      $elapsed += 2
      $status = & $adbExe shell getprop sys.boot_completed 2>$null
      if ($status -and $status.Trim() -eq '1') {
        $bootCompleted = $true
      }
    }
    Write-Host "  -> May ao Pixel_8a da san sang!" -ForegroundColor Green
  } else {
    Write-Host "  -> May ao da dang chay san!" -ForegroundColor Green
  }

  Write-Host "`n[3/3] Khoi chay Flutter tren Android Emulator..." -ForegroundColor Cyan
  Write-Host "`n========================================================" -ForegroundColor Magenta
  Write-Host "  Nhan 'r' de Hot Reload, 'R' de Hot Restart, 'q' de thoat." -ForegroundColor Magenta
  Write-Host "========================================================`n" -ForegroundColor Magenta
  Set-Location (Join-Path $repoRoot "apps\mobile_flutter")
  & flutter run --flavor dev --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEV_AUTH_ENABLED=true
}

