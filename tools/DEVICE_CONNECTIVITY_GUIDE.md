# Project PARAKH — Physical Device & Backend Connectivity Guide

This guide details how to establish reliable, zero-latency communication between the **Project PARAKH Flutter Mobile App** running on physical Android devices (e.g., Xiaomi 2312DRA50I / Android 14+) and the local **FastAPI Backend Server**.

---

## 1. Prerequisites

1. **Backend Server Running**:
   The FastAPI backend must be started listening on `0.0.0.0` (all host network interfaces):
   ```powershell
   cd backend
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

2. **Android Device**:
   * Developer Options & **USB Debugging** enabled.
   * Device connected via USB cable or on the same Wi-Fi network.

---

## 2. Option A: Wired USB Connection (Recommended for Zero Latency & Stability)

When connected via USB cable, use **ADB Reverse Port Forwarding**. This routes requests sent to `http://127.0.0.1:8000` or `http://localhost:8000` on the phone directly through the USB cable to the PC host.

### Setup Steps:
1. Locate `adb.exe` (typically in `C:\Users\<User>\AppData\Local\Android\Sdk\platform-tools\adb.exe`).
2. Verify connected device:
   ```powershell
   adb devices
   ```
3. Enable reverse port forwarding for port 8000:
   ```powershell
   adb reverse tcp:8000 tcp:8000
   ```
4. Configure Flutter Base URL:
   * In `frontend/lib/core/constants.dart`, set `defaultApiBaseUrl` or `localhostApiUrl` to `http://127.0.0.1:8000/api/v1`.
   * Or update it on the fly inside the app via **Inspector Settings** (`/profile`).

5. Run Flutter:
   ```powershell
   cd frontend
   flutter run -d <device_id>
   ```

---

## 3. Option B: Wireless Wi-Fi Connection

When connected wirelessly on the same local network (Wi-Fi), the mobile device communicates directly with the PC's Wi-Fi IP address.

### Setup Steps:
1. Find your PC's Local Wi-Fi IPv4 address:
   ```powershell
   ipconfig
   ```
   *Example IPv4 Address: `172.23.51.59`*

2. Pair & Connect Wireless ADB (Optional, for wireless debugging):
   * On device: Settings -> Developer Options -> Wireless Debugging -> Pair device with pairing code.
   ```powershell
   adb pair <IP>:<Pairing_Port>
   adb connect <IP>:<ADB_Port>
   ```

3. Configure Flutter Base URL:
   * Open `frontend/lib/core/constants.dart` and ensure `defaultApiBaseUrl` matches your PC's Wi-Fi IP:
     ```dart
     static const String defaultApiBaseUrl = 'http://172.23.51.59:8000/api/v1';
     ```
   * Alternatively, launch the app and navigate to **Inspector Settings** (`/profile`), enter `http://<YOUR_PC_IP>:8000/api/v1`, and click **UPDATE GATEWAY URL**.

4. Verify Windows Firewall:
   * Ensure Windows Defender Firewall allows inbound TCP connections on port **8000** for Private/Domain networks.

---

## 4. Automation Tool (`tools/connect_device.ps1` & `tools/connect_device.bat`)

To streamline device connection setup, use the provided helper script in `tools/`:

### Running via PowerShell:
```powershell
.\tools\connect_device.ps1
```

### What the tool does automatically:
1. Locates `adb.exe` in the system path or default Android SDK location.
2. Lists all connected wired and wireless devices.
3. Automatically executes `adb reverse tcp:8000 tcp:8000` for attached USB devices.
4. Queries network interfaces for active Wi-Fi IPv4 addresses.
5. Performs a live HTTP health check (`/api/v1/health`) against both `127.0.0.1:8000` and `LAN_IP:8000`.
6. Provides a one-click launcher for `flutter run`.

---

## 5. Troubleshooting & FAQ

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `Lost connection to device` | USB cable loose, ADB daemon restart, or app crash during deployment | Re-plug USB cable, run `adb kill-server; adb start-server`, and re-run `adb reverse tcp:8000 tcp:8000`. |
| `SocketException / Connection Refused` | Backend not running or listening on `127.0.0.1` instead of `0.0.0.0` | Start backend with `--host 0.0.0.0 --port 8000`. |
| `Permission No Allow` on Splash Screen | Duplicate permission request canceled by Android OS | Tap **Re-check** or **App Settings** on the splash screen to grant location permissions. |
