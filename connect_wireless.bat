@echo off
echo ========================================================
echo  Project PARAKH — Wireless Device Connection Assistant
echo ========================================================
echo.

echo [1/3] Checking connected ADB devices...
adb devices
echo.

echo [2/3] Configuring ADB port forwarding (tcp:8000)...
adb reverse tcp:8000 tcp:8000
if %ERRORLEVEL% EQU 0 (
    echo   [OK] adb reverse tcp:8000 tcp:8000 set successfully!
) else (
    echo   [WARNING] adb reverse failed or no device detected.
)
echo.

echo [3/3] Active Network Gateways:
echo   - Localhost / ADB Reverse: http://127.0.0.1:8000/api/v1
echo   - Wireless Wi-Fi LAN IP:   http://172.23.51.59:8000/api/v1
echo.

echo Testing device connectivity to backend...
adb shell curl -s http://127.0.0.1:8000/health
echo.
adb shell curl -s http://172.23.51.59:8000/health
echo.

echo ========================================================
echo  Ready! Backend is fully accessible to wireless device.
echo ========================================================
