$ErrorActionPreference = 'Stop'
$checklistPath = Join-Path $PSScriptRoot '..\docs\flutter-migration-checklist.md'
$content = Get-Content -LiteralPath $checklistPath -Raw -Encoding UTF8

$completed = [regex]::Matches($content, '(?m)^\s*-\s+\[x\]').Count
$open = [regex]::Matches($content, '(?m)^\s*-\s+\[ \]').Count
$summary = [regex]::Match($content, 'Current detailed count:\s+\*\*(\d+) completed / (\d+) open gates\*\*')
if (-not $summary.Success) { throw 'Checklist summary line was not found.' }

$summaryCompleted = [int]$summary.Groups[1].Value
$summaryOpen = [int]$summary.Groups[2].Value
if ($completed -ne $summaryCompleted -or $open -ne $summaryOpen) {
  throw "Checklist count mismatch: actual $completed/$open, summary $summaryCompleted/$summaryOpen."
}

Write-Host "Flutter checklist count verified: $completed completed / $open open gates."
