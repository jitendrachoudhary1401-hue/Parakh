Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Project PARAKH - Wireless Device Connection Assistant" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Get connected ADB devices
Write-Host "[1/3] Checking connected ADB devices..." -ForegroundColor Yellow
$rawDevices = adb devices
$rawDevices | ForEach-Object { Write-Host "  $_" }
Write-Host ""

$deviceSerials = @()
foreach ($line in $rawDevices) {
    if ($line.EndsWith("device") -and -not $line.StartsWith("List of")) {
        $parts = $line -split "\t"
        if ($parts.Length -ge 1) {
            $deviceSerials += $parts[0].Trim()
        }
    }
}

# 2. Get active Wi-Fi IPv4 address
$wifiIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias '*Wi-Fi*' -ErrorAction SilentlyContinue | 
           Where-Object { $_.IPAddress -notlike '169.254*' } | 
           Select-Object -ExpandProperty IPAddress -First 1)
if (-not $wifiIp) { $wifiIp = "10.224.19.59" }

# 3. Configure port forwarding for all attached devices
Write-Host "[2/3] Configuring ADB port forwarding (tcp:8000)..." -ForegroundColor Yellow
if ($deviceSerials.Count -eq 0) {
    Write-Host "  [WARNING] No active ADB devices detected." -ForegroundColor Red
} else {
    foreach ($serial in $deviceSerials) {
        Write-Host "  Forwarding tcp:8000 on device: [$serial]..." -ForegroundColor Green
        & adb -s $serial reverse tcp:8000 tcp:8000
    }
}
Write-Host ""

Write-Host "[3/3] Active Network Gateways:" -ForegroundColor Yellow
Write-Host "  - Localhost / ADB Reverse: http://127.0.0.1:8000/api/v1" -ForegroundColor White
$wifiGateway = "  - Wireless Wi-Fi LAN IP:   http://" + $wifiIp + ":8000/api/v1"
Write-Host $wifiGateway -ForegroundColor White
Write-Host ""

# 4. Test connectivity from attached devices
Write-Host "Testing device connectivity to backend..." -ForegroundColor Yellow
foreach ($serial in $deviceSerials) {
    $deviceHeader = "--- Device [" + $serial + "] ---"
    Write-Host $deviceHeader -ForegroundColor Cyan
    Write-Host "[Test 1: Via ADB Reverse (127.0.0.1)]:" -ForegroundColor White
    $res1 = & adb -s $serial shell curl -s http://127.0.0.1:8000/api/v1/health
    Write-Host "  $res1" -ForegroundColor Green

    $wifiTestHeader = "[Test 2: Via Wireless Wi-Fi LAN (" + $wifiIp + ")]:"
    Write-Host $wifiTestHeader -ForegroundColor White
    $wifiUrl = "http://" + $wifiIp + ":8000/api/v1/health"
    $res2 = & adb -s $serial shell curl -s $wifiUrl
    Write-Host "  $res2" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Ready! Backend is fully accessible to wireless device." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
