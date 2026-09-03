param(
  [Parameter(Mandatory = $true)]
  [string]$ArtifactPath
)

$ErrorActionPreference = 'Stop'
$resolvedArtifact = Resolve-Path -LiteralPath $ArtifactPath -ErrorAction Stop

# Scan text embedded in APK/AAB/IPA archives as well as plain files. This is a
# release safety net, not a replacement for secret-manager and signing review.
$forbidden = @(
  'http://localhost',
  'http://127\.0\.0\.1',
  'http://10\.0\.2\.2',
  'DEV_AUTH_ENABLED=true',
  'Bearer dev:',
  'SUPABASE_SERVICE_ROLE_KEY',
  'SUPABASE_SERVICE_ROLE',
  'PRIVATE_KEY'
)

function Test-Content([string]$Name, [byte[]]$Bytes) {
  $text = [Text.Encoding]::UTF8.GetString($Bytes)
  foreach ($pattern in $forbidden) {
    if ($text -match $pattern) {
      return "$Name :: $pattern"
    }
  }
  return $null
}

$violations = [System.Collections.Generic.List[string]]::new()
$extension = [IO.Path]::GetExtension($resolvedArtifact.Path).ToLowerInvariant()

if ($extension -in @('.apk', '.aab', '.ipa', '.zip')) {
  $archive = [IO.Compression.ZipFile]::OpenRead($resolvedArtifact.Path)
  try {
    foreach ($entry in $archive.Entries) {
      if ($entry.Length -eq 0) { continue }
      $stream = $entry.Open()
      $memory = [IO.MemoryStream]::new()
      try {
        $stream.CopyTo($memory)
        $match = Test-Content $entry.FullName $memory.ToArray()
        if ($match) { $violations.Add($match) }
      }
      finally {
        $memory.Dispose()
        $stream.Dispose()
      }
    }
  }
  finally {
    $archive.Dispose()
  }
}
else {
  $match = Test-Content $resolvedArtifact.Path ([IO.File]::ReadAllBytes($resolvedArtifact.Path))
  if ($match) { $violations.Add($match) }
}

if ($violations.Count -gt 0) {
  Write-Error "Release artifact contains forbidden production config or secret markers:`n$($violations -join "`n")"
  exit 1
}

Write-Host "Release artifact scan passed: $resolvedArtifact"
