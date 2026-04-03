# ReelBoost: phone par app chalane ke liye (Wireless debugging + flutter run)
# Usage: .\scripts\run_flutter_on_phone.ps1
# Optional: $env:PC_LAN_IP = "192.168.29.x"  (PC ka Wi-Fi IPv4 — ipconfig se)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

Write-Host "=== ADB devices ===" -ForegroundColor Cyan
adb devices
$out = adb devices 2>&1 | Out-String
if ($out -notmatch "\tdevice") {
    Write-Host ""
    Write-Host "PHONE CONNECT NAHI HAI." -ForegroundColor Yellow
    Write-Host "1) Phone: Settings > Developer options > Wireless debugging ON"
    Write-Host "2) Jo IP:PORT dikhe (debug), PC par chalao:"
    Write-Host "   adb connect YOUR_IP:PORT"
    Write-Host "3) Phir ye script dubara chalao."
    exit 1
}

$pcIp = $env:PC_LAN_IP
if (-not $pcIp) {
    Write-Host ""
    Write-Host "PC ka LAN IP set karo (same Wi-Fi). Example:" -ForegroundColor Yellow
    Write-Host '  $env:PC_LAN_IP="192.168.29.10"; .\scripts\run_flutter_on_phone.ps1'
    Write-Host "ipconfig -> Wireless LAN adapter Wi-Fi -> IPv4"
    $pcIp = "192.168.1.7"
    Write-Host "Default use ho raha hai: $pcIp (galat ho to PC_LAN_IP set karo)" -ForegroundColor DarkYellow
}

$api = "http://${pcIp}:3000/api"
Write-Host ""
Write-Host "flutter run --dart-define=API_BASE_URL=$api" -ForegroundColor Green
flutter run --dart-define="API_BASE_URL=$api"
