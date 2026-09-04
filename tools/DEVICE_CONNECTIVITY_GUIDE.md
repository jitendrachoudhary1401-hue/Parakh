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
1. Locate `adb.exe`:
   * Path on your system: `C:\Users\rajku\AppData\Local\Android\Sdk\platform-tools\adb.exe`
   * **Note**: `C:\Users\rajku\AppData\Local\Android\Sdk\platform-tools` has been added to your User `PATH`.
2. Verify connected device:
   ```powershell
   adb devices
   ```
   *(Expected: `cbd0bf35 device` for Xiaomi Redmi Note 13 Pro 5G / 2312DRA50I)*
3. Enable reverse port forwarding for port 8000:
   ```powershell
   adb reverse tcp:8000 tcp:8000
   ```
4. Run Flutter:
   ```powershell
   cd frontend
   flutter run -d cbd0bf35
   ```

> [!TIP]
> **Or simply run the automated script from project root:**
> ```powershell
> .\tools\connect_device.ps1
> ```

---

## 3. Option B: Wireless Wi-Fi Connection

When connected wirelessly on the same local network (Wi-Fi), the mobile device communicates directly with the PC's Wi-Fi IP address.

### Setup Steps:
1. Find your PC's Local Wi-Fi IPv4 address:
   ```powershell
   ipconfig
   ```
   *Current Active IPv4 Address: `10.199.56.59`*

2. Pair & Connect Wireless ADB (Optional, for wireless debugging):
   * On device: Settings -> Developer Options -> Wireless Debugging -> Pair device with pairing code.
   ```powershell
   adb pair <IP>:<Pairing_Port>
   adb connect <IP>:<ADB_Port>
   ```

3. Configure Flutter Base URL:
   * `frontend/lib/core/constants.dart` is pre-configured with:
     ```dart
     static const String defaultApiBaseUrl = 'http://127.0.0.1:8000/api/v1'; // USB via ADB reverse
     static const String wifiLanApiUrl = 'http://10.199.56.59:8000/api/v1'; // Wi-Fi LAN IP
     ```
   * Alternatively, launch the app and navigate to **Inspector Settings** (`/profile`), enter `http://10.199.56.59:8000/api/v1`, and click **UPDATE GATEWAY URL**.

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
| `adb.exe: failed to install... (Exit code 1)` | Xiaomi/MIUI/HyperOS requires "Install via USB" permission | In phone **Settings -> Additional settings -> Developer options**: enable **Install via USB**. Keep the screen unlocked during install and tap **Install** if prompted. |
| `adb: The term 'adb' is not recognized` | Android SDK `platform-tools` was not in user's PATH | Re-open your PowerShell terminal (it has now been added to your User PATH) or run `.\tools\connect_device.ps1`. |
| `cd : Illegal characters in path` | Angle brackets `<User>` typed literally in PowerShell | Replace `<User>` with `rajku`, and point to the folder `platform-tools`, not `adb.exe`. |
| `Lost connection to device` | USB cable loose, ADB daemon restart, or app crash during deployment | Re-plug USB cable, run `adb kill-server; adb start-server`, and re-run `adb reverse tcp:8000 tcp:8000`. |
| `SocketException / Connection Refused` | Backend not running or listening on `127.0.0.1` instead of `0.0.0.0` | Start backend with `--host 0.0.0.0 --port 8000`. |
| `Permission No Allow` on Splash Screen | Duplicate permission request canceled by Android OS | Tap **Re-check** or **App Settings** on the splash screen to grant location permissions. |
