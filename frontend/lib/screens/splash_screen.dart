import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/parakh_logo.dart';

/// Video Splash Screen with Mandatory Location Permission Enforcement
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  // Location permission state
  bool _isLocationPermissionGranted = false;
  bool _isCheckingPermission = true;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _initVideoSplash();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isLocationPermissionGranted) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // If already granted, allow user to use app immediately
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (!mounted) return;
        setState(() {
          _isLocationPermissionGranted = true;
          _isCheckingPermission = false;
        });
        _navigateToNextScreen();
        return;
      }

      // If not granted, set state to show permission request UI
      if (!mounted) return;
      setState(() {
        _isLocationPermissionGranted = false;
        _isCheckingPermission = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocationPermissionGranted = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _handlePermissionRequest() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }

      // Re-verify after prompt or settings return
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (!mounted) return;
        setState(() {
          _isLocationPermissionGranted = true;
          _isCheckingPermission = false;
        });
        _navigateToNextScreen();
      } else {
        if (!mounted) return;
        setState(() {
          _isLocationPermissionGranted = false;
          _isCheckingPermission = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocationPermissionGranted = false;
        _isCheckingPermission = false;
      });
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> _initVideoSplash() async {
    try {
      _videoController = VideoPlayerController.asset('assets/splash_video.mp4');
      await _videoController!.initialize();
      await _videoController!.setLooping(false);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      // Fallback timer if video playback fails or asset is missing
      _scheduleFallbackNavigation();
    }
  }

  void _videoListener() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying &&
        _videoController!.value.position >= _videoController!.value.duration) {
      if (_isLocationPermissionGranted && !_isCheckingPermission) {
        _navigateToNextScreen();
      }
    }
  }

  void _scheduleFallbackNavigation() {
    Timer(const Duration(milliseconds: 3000), () {
      if (_isLocationPermissionGranted && !_isCheckingPermission) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
      _videoController?.pause();
    } catch (_) {}

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // If there's a cached user + token, validate it against the backend
    if (auth.currentUser != null && auth.storage.getToken() != null) {
      final isValid = await auth.validateSession();
      if (isValid && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      }
    }

    // No valid session — route to login
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video background player if initialized and permission is granted or checking
          if (_isVideoInitialized &&
              _videoController != null &&
              (_isLocationPermissionGranted || _isCheckingPermission))
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else if (_isLocationPermissionGranted || _isCheckingPermission)
            // Fallback UI while loading video
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ParakhLogo(width: 180, height: 98, showText: true),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),

          // Permission Blocker UI (shows if permission denied and not checking)
          if (!_isCheckingPermission && !_isLocationPermissionGranted)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Center(
                child: Card(
                  color: AppTheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          color: AppTheme.error,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Location Access Required',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Project PARAKH requires location services to log inspection coordinates and verify evidence committed to the Hyperledger Fabric blockchain. You cannot use the application without location permissions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handlePermissionRequest,
                            icon: const Icon(Icons.location_on),
                            label: const Text('Grant Access / Enable GPS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _checkLocationPermission,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Re-check'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => Geolocator.openAppSettings(),
                                icon: const Icon(Icons.settings, size: 16),
                                label: const Text('App Settings'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
