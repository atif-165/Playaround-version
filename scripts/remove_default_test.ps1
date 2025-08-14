$ErrorActionPreference='Stop'
$ts = Get-Date -Format 'yyyyMMdd-HHmm'
# decide backup base path
$backupBase = ''
if (Test-Path '/tmp') {
  $backupBase = '/tmp'
} else {
  $backupBase = (Join-Path (Get-Location).Path 'backup')
}

if (-not (Test-Path $backupBase)) { New-Item -ItemType Directory -Force -Path $backupBase | Out-Null }
$zip = Join-Path $backupBase ("playaround_cleanup_backup_" + $ts + ".zip")

$log = 'build/inventory/removal_log.jsonl'
if (-not (Test-Path $log)) { New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; New-Item -ItemType File -Force -Path $log | Out-Null }

if (Test-Path 'test/widget_test.dart') {
  Compress-Archive -Path 'test/widget_test.dart' -DestinationPath $zip -Update
  $obj = [PSCustomObject]@{ path='test/widget_test.dart'; reason='example default test removed'; ts=$ts }
  $obj | ConvertTo-Json -Depth 5 | Add-Content -Path $log
  Remove-Item 'test/widget_test.dart' -Force
  Write-Output $zip
} else {
  Write-Output ''
}

