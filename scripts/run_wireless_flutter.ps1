# Run Flutter on wireless ADB device with API pointing at this PC (same Wi‑Fi).
# 1. Phone: Developer options → Wireless debugging → ON
# 2. Copy IP address and port (connect port, not pairing)
# 3. Run: .\scripts\run_wireless_flutter.ps1 -Device "192.168.29.33:PORT"

param(
  [Parameter(Mandatory = $false)]
  [string] $Device = "",
  [string] $ApiPort = "3000"
)

$ErrorActionPreference = "Stop"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
  Write-Error "adb not found at $adb"
}

$pcIp = (
  Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.InterfaceAlias -match 'Wi-?Fi' -and $_.IPAddress -notmatch '^127\.' } |
  Select-Object -First 1 -ExpandProperty IPAddress
)
if (-not $pcIp) {
  $pcIp = "192.168.29.40"
  Write-Warning "Could not detect Wi-Fi IP; using fallback $pcIp. Set manually if wrong."
}

$apiBase = "http://${pcIp}:${ApiPort}/api"
Write-Host "API_BASE_URL -> $apiBase" -ForegroundColor Cyan

if (-not $Device) {
  Write-Host @'
Usage:
  Phone: Settings - Developer options - Wireless debugging - ON
  Copy "IP address and port" from that screen (example: 192.168.29.33:45678)

  Then run:
    .\scripts\run_wireless_flutter.ps1 -Device "192.168.29.33:45678"

'@ -ForegroundColor Yellow
  exit 1
}

Write-Host "adb connect $Device" -ForegroundColor Cyan
& $adb connect $Device
Start-Sleep -Seconds 1

& $adb devices -l
$flutterArgs = @(
  "run",
  "-d", $Device,
  "--dart-define=API_BASE_URL=$apiBase"
)

Set-Location $PSScriptRoot\..
Write-Host ('flutter ' + ($flutterArgs -join ' ')) -ForegroundColor Cyan
& flutter @flutterArgs
