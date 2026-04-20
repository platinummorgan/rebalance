param(
    [switch]$SkipClean
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$definesFile = Join-Path $repoRoot "config\dart_defines.production.json"
$definesTemplate = Join-Path $repoRoot "config\dart_defines.production.example.json"

if (-not (Test-Path $definesFile)) {
    Write-Error @"
Missing required file: $definesFile

Create it from template:
  Copy-Item "$definesTemplate" "$definesFile"
Then set real values for:
  ENTITLEMENT_API_BASE_URL
  ENTITLEMENT_API_KEY
"@
}

Push-Location $repoRoot
try {
    if (-not $SkipClean) {
        flutter clean
    }

    flutter pub get
    flutter pub run build_runner build --delete-conflicting-outputs

    flutter build appbundle --release `
        --dart-define-from-file="$definesFile" `
        --obfuscate `
        --split-debug-info=build/symbols/

    Write-Host ""
    Write-Host "Build complete:"
    Write-Host "  build/app/outputs/bundle/release/app-release.aab"
} finally {
    Pop-Location
}
