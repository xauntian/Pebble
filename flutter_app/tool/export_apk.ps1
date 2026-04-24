param(
  [ValidateSet("debug", "release")]
  [string]$BuildMode = "debug",
  [string]$OutputDirectory = "D:\download"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $projectRoot

$pubspec = Get-Content "pubspec.yaml"
$versionLine = $pubspec | Where-Object { $_ -match "^version:\s*(.+)$" } | Select-Object -First 1
if (-not $versionLine) {
  throw "Could not find version in pubspec.yaml"
}

$version = ($versionLine -replace "^version:\s*", "").Trim()
$versionName = ($version -split "\+")[0]
$buildNumber = if ($version.Contains("+")) { ($version -split "\+")[1] } else { "0" }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$flutter = Join-Path $projectRoot "..\flutter\bin\flutter.bat"
& $flutter build apk "--$BuildMode"
if ($LASTEXITCODE -ne 0) {
  throw "flutter build apk --$BuildMode failed with exit code $LASTEXITCODE"
}

$sourceApk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-$BuildMode.apk"
if (-not (Test-Path $sourceApk)) {
  throw "Expected APK was not found at $sourceApk"
}

New-Item -ItemType Directory -Force $OutputDirectory | Out-Null

$baseName = "pebble-v$versionName+$buildNumber-$BuildMode-$stamp"
$apkPath = Join-Path $OutputDirectory "$baseName.apk"
$infoPath = Join-Path $OutputDirectory "$baseName.txt"

Copy-Item -LiteralPath $sourceApk -Destination $apkPath -Force

$hash = Get-FileHash -LiteralPath $apkPath -Algorithm SHA256
$info = @(
  "name: Pebble",
  "version: $versionName",
  "build_number: $buildNumber",
  "build_mode: $BuildMode",
  "created_at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")",
  "apk: $apkPath",
  "sha256: $($hash.Hash)"
)
$info | Set-Content -LiteralPath $infoPath -Encoding UTF8

Write-Host "APK exported: $apkPath"
Write-Host "Version info: $infoPath"
