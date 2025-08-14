Param(
  [string]$RemovalLog = "build/inventory/removal_log.jsonl",
  [string]$BackupBase = "/tmp"
)

$ErrorActionPreference = 'Stop'
$ts = Get-Date -Format 'yyyyMMdd-HHmm'

if (-not (Test-Path $RemovalLog)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $RemovalLog) | Out-Null
  New-Item -ItemType File -Force -Path $RemovalLog | Out-Null
}

# Select backup destination
if (-not (Test-Path $BackupBase)) {
  $BackupBase = (Join-Path (Get-Location).Path 'backup')
  New-Item -ItemType Directory -Force -Path $BackupBase | Out-Null
}
$backupZip = Join-Path $BackupBase ("playaround_cleanup_backup_" + $ts + ".zip")

# Candidate files to remove/move
$patterns = @('.DS_Store','*.orig','*~')
$candidates = @()
foreach ($pat in $patterns) {
  $candidates += Get-ChildItem -Recurse -File -Filter $pat | ForEach-Object { $_.FullName }
}

# Demo/example directories
$demoNames = @('example','examples','samples','sample_app','demo','playground','sandbox','testdata','androidTest','iosTest')
$demoDirs = Get-ChildItem -Directory -Recurse | Where-Object { ($demoNames -contains $_.Name) -or ($_.Name -like 'clone_*') } | ForEach-Object { $_.FullName }

# Aggregate list
$toArchive = @()
foreach ($f in $candidates) { $toArchive += $f }
foreach ($d in $demoDirs) { $toArchive += $d }

if ($toArchive.Count -gt 0) {
  # Record to removal log with reasons
  foreach ($f in $candidates) {
    $rel = $f.Replace((Get-Location).Path + '\\','')
    $obj = [PSCustomObject]@{ path=$rel; reason='temporary/duplicate file'; ts=$ts }
    $obj | ConvertTo-Json -Depth 5 | Add-Content -Path $RemovalLog
  }
  foreach ($d in $demoDirs) {
    $rel = $d.Replace((Get-Location).Path + '\\','')
    $obj = [PSCustomObject]@{ path=$rel; reason='example/demo folder'; ts=$ts }
    $obj | ConvertTo-Json -Depth 5 | Add-Content -Path $RemovalLog
  }

  # Create zip and remove from workspace
  Compress-Archive -Path $toArchive -DestinationPath $backupZip -Force
  foreach ($p in $toArchive) { if (Test-Path $p) { Remove-Item -Recurse -Force $p } }
  Write-Output $backupZip
} else {
  Write-Output ''
}

