# MyBudget Windows Build Script
# This script builds the application, creates a Portable ZIP, and generates a Setup Installer.

# 1. Clean and Build
Write-Host "Building Windows Application..." -ForegroundColor Cyan
flutter build windows --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Create Distribution Folder
$distDir = "build\windows\installer_output"
if (!(Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir
}

# 3. Create Setup Installer
Write-Host "Creating Setup Installer..." -ForegroundColor Cyan
$iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if (Test-Path $iscc) {
    & $iscc "windows\installer\mybudget_setup.iss"
} else {
    Write-Host "Inno Setup (ISCC.exe) not found at $iscc. Skipping installer creation." -ForegroundColor Yellow
    Write-Host "You can download it from https://jrsoftware.org/isdl.php" -ForegroundColor Gray
}

Write-Host "`nBuild Complete!" -ForegroundColor Green
Write-Host "Setup Installer: $distDir\MyBudget-Setup.exe (if created)"
