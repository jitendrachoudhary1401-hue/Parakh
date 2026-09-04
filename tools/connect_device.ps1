# Project PARAKH - Device and Backend Connectivity Automation Tool
# Supports Wired (USB Debugging) and Wireless (Wi-Fi ADB) Setup

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   PROJECT PARAKH - DEVICE CONNECTIVITY AUTOMATION TOOL " -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate ADB Executable
$adbPath = "adb"
if (-not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    $possiblePath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $possiblePath) {
        $adbPath = $possiblePath
    } else {
        Write-Host "[ERROR] ADB executable not found in PATH or Android SDK location." -ForegroundColor Red
        Write-Host "Please ensure Android SDK platform-tools are installed." -ForegroundColor Red
        exit 1
    }
}

Write-Host "[1/4] Checking Connected ADB Devices..." -ForegroundColor Green
$devicesOutput = & $adbPath devices
$deviceLines = $devicesOutput | Where-Object { $_ -match "`tdevice$" }

if (-not $deviceLines) {
    Write-Host "[WARNING] No physical or wireless devices found via ADB." -ForegroundColor Yellow
    Write-Host "Please connect your phone via USB with USB Debugging enabled, or pair via Wireless Debugging." -ForegroundColor Yellow
} else {
    Write-Host "Found Attached Devices:" -ForegroundColor Cyan
    foreach ($line in $deviceLines) {
        Write-Host "  -> $line" -ForegroundColor White
    }
}

# 2. Setup ADB Reverse Port Forwarding (For Wired USB Connectivity)
Write-Host ""
Write-Host "[2/4] Configuring ADB Reverse Port Forwarding (Port 8000)..." -ForegroundColor Green
try {
    & $adbPath reverse tcp:8000 tcp:8000
    Write-Host "  [OK] Forwarded tcp:8000 -> tcp:8000 on connected Android device(s)." -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Failed to configure reverse port forwarding." -ForegroundColor Yellow
}

# 3. Detect Wi-Fi LAN IP Address (For Wireless Connectivity)
Write-Host ""
Write-Host "[3/4] Detecting Local Wi-Fi IPv4 Address..." -ForegroundColor Green
$wifiIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "*Wi-Fi*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) | Select-Object -First 1

if (-not $wifiIP) {
    $wifiIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -ExpandProperty IPAddress) | Select-Object -First 1
}

if ($wifiIP) {
    Write-Host "  [OK] Local Network IPv4 Address: http://$wifiIP`:8000/api/v1" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Could not detect active Wi-Fi IPv4 address." -ForegroundColor Yellow
}

# 4. Backend Health Check Verification
Write-Host ""
Write-Host "[4/4] Verifying FastAPI Backend Health..." -ForegroundColor Green
$backendUrlLocal = "http://127.0.0.1:8000/api/v1/health"

try {
    $response = Invoke-RestMethod -Uri $backendUrlLocal -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  [OK] FastAPI Backend is HEALTHY at http://127.0.0.1:8000" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Backend health check failed on http://127.0.0.1:8000!" -ForegroundColor Red
    Write-Host "  Make sure your FastAPI server is running with:" -ForegroundColor Yellow
    Write-Host "  cd backend; uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " SUMMARY AND CONNECTIVITY STATUS:" -ForegroundColor Yellow
Write-Host "  * Wired USB Gateway URL : http://127.0.0.1:8000/api/v1 (via ADB reverse)" -ForegroundColor White
if ($wifiIP) {
    Write-Host "  * Wireless Wi-Fi Gateway: http://$wifiIP`:8000/api/v1" -ForegroundColor White
}
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
