param(
  [string]$SdkRoot = "$env:LOCALAPPDATA\Android\Sdk",
  [string]$JavaHome = "D:\Android\jbr",
  [string]$AvdName = 'Pixel_8a'
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $SdkRoot)) {
  $failures.Add("Android SDK not found: $SdkRoot")
}
if (-not (Test-Path -LiteralPath "$JavaHome\bin\java.exe")) {
  $failures.Add("JDK not found: $JavaHome\bin\java.exe")
}

$avdConfig = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd\config.ini"
if (-not (Test-Path -LiteralPath $avdConfig)) {
  $failures.Add("AVD config not found: $avdConfig")
}

if (Test-Path -LiteralPath $avdConfig) {
  $imageLine = Get-Content -LiteralPath $avdConfig | Where-Object { $_ -like 'image.sysdir.1=*' } | Select-Object -First 1
  if ($imageLine) {
    $imageRelativePath = ($imageLine -split '=', 2)[1].Trim()
    $imagePath = Join-Path $SdkRoot $imageRelativePath
    if (-not (Test-Path -LiteralPath (Join-Path $imagePath 'kernel-ranchu'))) {
      $failures.Add("AVD system image is incomplete; kernel-ranchu missing under $imagePath")
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host 'Android environment check failed:'
  $failures | ForEach-Object { Write-Host "- $_" }
  exit 1
}

Write-Host "Android environment check passed for AVD '$AvdName'."
