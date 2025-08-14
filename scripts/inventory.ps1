Param(
  [string]$OutDir = "build/inventory"
)

$ErrorActionPreference = 'Stop'

# Timestamp
$ts = Get-Date -Format 'yyyyMMdd-HHmm'

# Prepare output directory
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Dependencies (resolved)
$depsJsonPath = Join-Path $OutDir 'deps.json'
flutter pub deps --json | Out-File -FilePath $depsJsonPath -Encoding utf8
$depsObj = Get-Content $depsJsonPath -Raw | ConvertFrom-Json
$depsMap = @{}
if ($depsObj -and $depsObj.packages) {
  foreach ($p in $depsObj.packages) { $depsMap[$p.name] = $p.version }
}

# Files inventory
$root = (Get-Location).Path
$dartFiles = Get-ChildItem -Recurse -File -Filter *.dart | ForEach-Object {
  [PSCustomObject]@{
    path  = ($_.FullName.Replace($root + '\\','').Replace('\\','/'))
    bytes = $_.Length
  }
}

# Asset inventory: typical asset folders
$assetDirs = @('assets','images','fonts')
$assets = @()
foreach ($d in $assetDirs) {
  if (Test-Path $d) {
    $assets += Get-ChildItem $d -Recurse -File | ForEach-Object {
      [PSCustomObject]@{
        path  = ($_.FullName.Replace($root + '\\','').Replace('\\','/'))
        bytes = $_.Length
      }
    }
  }
}

# Suspicious folders (examples / demos / playgrounds / clones)
$suspiciousNames = @('example','examples','samples','sample_app','demo','playground','sandbox','testdata','androidTest','iosTest')
$suspicious = Get-ChildItem -Directory -Recurse |
  Where-Object { $n = $_.Name; ($suspiciousNames -contains $n) -or ($n -like 'clone_*') } |
  ForEach-Object { $_.FullName.Replace($root + '\\','').Replace('\\','/') }

$summary = [PSCustomObject]@{
  total_dart_files   = ($dartFiles | Measure-Object).Count
  total_assets       = ($assets | Measure-Object).Count
  total_dependencies = ($depsMap.Keys | Measure-Object).Count
}

$inv = [PSCustomObject]@{
  generated_at       = $ts
  dart_files         = $dartFiles
  assets             = $assets
  dependencies       = $depsMap
  suspicious_folders = $suspicious
  summary            = $summary
}

$inventoryPath = Join-Path $OutDir 'project_inventory.json'
$inv | ConvertTo-Json -Depth 10 | Out-File -FilePath $inventoryPath -Encoding utf8
Write-Output $inventoryPath

