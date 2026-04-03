# ReelBoost API — run from project root. Listens on 0.0.0.0:3000 (phone/LAN).
Set-Location $PSScriptRoot\backend
Write-Host "Starting backend (Ctrl+C to stop)..." -ForegroundColor Cyan
npm start
