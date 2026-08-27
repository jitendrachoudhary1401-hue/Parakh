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

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  // Location permission state
  bool _isLocationPermissionGranted = false;
  bool _isCheckingPermission = true;
  bool _isVideoFinished = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initVideoSplash();
  }

  Future<void> _checkLocationPermission() async {
    try {
      setState(() {
        _isCheckingPermission = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationPermissionGranted = false;
          _isCheckingPermission = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        setState(() {
          _isLocationPermissionGranted = true;
          _isCheckingPermission = false;
        });
        if (_isVideoFinished) {
          _navigateToNextScreen();
        }
      } else {
        setState(() {
          _isLocationPermissionGranted = false;
          _isCheckingPermission = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLocationPermissionGranted = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _handlePermissionRequest() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.requestPermission();
    }
    // Re-check after returning
    _checkLocationPermission();
  }

  Future<void> _initVideoSplash() async {
    try {
      _videoController = VideoPlayerController.asset('assets/splash_video.mp4');
      await _videoController!.initialize();
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
      _isVideoFinished = true;
      if (_isLocationPermissionGranted && !_isCheckingPermission) {
        _navigateToNextScreen();
      }
    }
  }

  void _scheduleFallbackNavigation() {
    Timer(const Duration(milliseconds: 3000), () {
      _isVideoFinished = true;
      if (_isLocationPermissionGranted && !_isCheckingPermission) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video background player if initialized and permission is granted or checking
          if (_isVideoInitialized && _videoController != null && (_isLocationPermissionGranted || _isCheckingPermission))
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ParakhLogo(width: 180, height: 98, showText: true),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),

          // Permission Blocker UI (shows if permission denied and not checking)
          if (!_isCheckingPermission && !_isLocationPermissionGranted)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                            icon: const Icon(Icons.settings),
                            label: const Text('Grant Location Access'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                          ),
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
