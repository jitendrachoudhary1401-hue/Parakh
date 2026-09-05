@echo off
setlocal enabledelayedexpansion
echo ========================================================
echo  Project PARAKH — Wireless Device Connection Assistant
echo ========================================================
echo.

echo [1/3] Checking connected ADB devices...
adb devices -l
echo.

:: Detect primary Wi-Fi IPv4 address
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias '*Wi-Fi*' | Where-Object { $_.IPAddress -notlike '169.254*' }).IPAddress"`) do (
    set WIFI_IP=%%A
)
if "%WIFI_IP%"=="" set WIFI_IP=10.224.19.59

echo [2/3] Configuring ADB port forwarding (tcp:8000)...
for /f "tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
        echo   Applying adb reverse to device [%%A]...
        adb -s %%A reverse tcp:8000 tcp:8000
    )
)
echo.

echo [3/3] Active Network Gateways:
echo   - Localhost / ADB Reverse: http://127.0.0.1:8000/api/v1
echo   - Wireless Wi-Fi LAN IP:   http://%WIFI_IP%:8000/api/v1
echo.

echo Testing device connectivity to backend...
for /f "tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
        echo --- Device [%%A] ---
        echo [Via ADB Reverse 127.0.0.1]:
        adb -s %%A shell curl -s http://127.0.0.1:8000/api/v1/health
        echo.
        echo [Via Wi-Fi LAN %WIFI_IP%]:
        adb -s %%A shell curl -s http://%WIFI_IP%:8000/api/v1/health
        echo.
    )
)

echo ========================================================
echo  Ready! Backend is fully accessible to wireless device.
echo ========================================================
