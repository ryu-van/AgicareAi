param([switch]$RequireSigning)
$ErrorActionPreference = 'Stop'
if ($RequireSigning -and -not (Test-Path android/key.properties)) { throw 'android/key.properties is required for a signed production release.' }
if (-not $env:API_BASE_URL -or $env:API_BASE_URL -notmatch '^https://') { throw 'API_BASE_URL=https://... is required.' }
if (-not (Test-Path pubspec.lock)) { throw 'pubspec.lock is required for a reproducible release.' }
Write-Host 'Release preflight passed.'
