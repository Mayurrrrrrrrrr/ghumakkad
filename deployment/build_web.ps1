# Configuration
$ProjectRoot = Get-Location
$FrontendDir = Join-Path $ProjectRoot "frontend"
$BackendWebDir = Join-Path $ProjectRoot "backend\web"

Write-Host "[*] Starting Ghumakkad Web Build Process..." -ForegroundColor Cyan

# 1. Clean and Build Flutter Web
if (-not (Test-Path $FrontendDir)) {
    Write-Error "Frontend directory not found at $FrontendDir"
    exit
}

Push-Location $FrontendDir
Write-Host "[+] Building Flutter Web..." -ForegroundColor Yellow
flutter clean
flutter build web --release --base-href /
Pop-Location

# 2. Sync with Backend
Write-Host "[+] Moving build files to backend/web..." -ForegroundColor Yellow
if (Test-Path $BackendWebDir) {
    Remove-Item -Recurse -Force $BackendWebDir
}
New-Item -ItemType Directory -Force -Path $BackendWebDir | Out-Null

$BuildOutputDir = Join-Path $FrontendDir "build\web"
if (Test-Path $BuildOutputDir) {
    Copy-Item -Path "$BuildOutputDir\*" -Destination $BackendWebDir -Recurse
} else {
    Write-Error "[-] Build output not found at $BuildOutputDir. Build might have failed."
    exit
}

# 3. Final steps
Write-Host "`n[OK] Build Complete!" -ForegroundColor Green
Write-Host "    Location: $BackendWebDir"
Write-Host "    To run the server:"
Write-Host "    cd backend"
Write-Host "    dart bin/server.dart"
