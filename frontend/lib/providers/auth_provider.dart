import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../models/models.dart';

/// Authentication Provider managing Inspector JWT sessions & biometric unlock
class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final bool _biometricEnabled = true;
  bool _isSessionValidated = false;

  AuthProvider(this._apiClient, this._storage) {
    _loadPersistedUser();
  }

  ApiClient get apiClient => _apiClient;
  StorageService get storage => _storage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _storage.getToken() != null && _isSessionValidated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get biometricEnabled => _biometricEnabled;

  void updateBaseUrl(String url) {
    _apiClient.updateBaseUrl(url);
    _storage.setCustomApiUrl(url);
    notifyListeners();
  }

  void updateServerUrl(String url) => updateBaseUrl(url);

  /// Switch active role perspective for RBAC dashboard view testing
  void switchRole(UserRole newRole) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: newRole);
      _storage.saveUser(_currentUser!);
      notifyListeners();
    }
  }

  void _loadPersistedUser() {
    _currentUser = _storage.getUser();
    // Don't mark session as validated yet — must verify token against backend
    _isSessionValidated = false;
    notifyListeners();
  }

  /// Validate the stored token against the backend.
  /// Returns true if the token is valid and the session is still active.
  Future<bool> validateSession() async {
    final token = _storage.getToken();
    if (token == null || _currentUser == null) {
      _isSessionValidated = false;
      return false;
    }

    try {
      // Attempt a lightweight authenticated request to verify the token
      final response = await _apiClient.get('/health');
      if (response.statusCode == 401) {
        // Token is invalid/expired — clear stale auth
        await _clearStaleAuth();
        return false;
      }
      // Token is valid
      _isSessionValidated = true;
      notifyListeners();
      return true;
    } catch (_) {
      // Network error — don't clear auth, just mark as not validated
      _isSessionValidated = false;
      return false;
    }
  }

  Future<void> _clearStaleAuth() async {
    _currentUser = null;
    _isSessionValidated = false;
    await _storage.clearAuth();
    notifyListeners();
  }

  /// Official ID + Password Login
  Future<bool> login({
    required String officialId,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        AppConstants.authLogin,
        body: {
          'email': officialId.contains('@') ? officialId : '$officialId@doca.gov.in',
          'password': password,
        },
      );

      if (response.success && response.data != null) {
        final token = response.data!['access_token'] ?? response.data!['token'];
        final userData = response.data!['user'];

        if (token != null && userData != null && userData is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(userData, token: token);
          await _storage.saveToken(token);
          await _storage.saveUser(_currentUser!);
          _isSessionValidated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage = response.message ?? 'Invalid credentials or authentication error.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Authentication error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Real Biometric Hardware Quick Unlock (Fingerprint / Face ID)
  /// Biometric only works if the user has already logged in with valid credentials
  /// and has a valid token stored. It does NOT auto-login with any credentials.
  Future<bool> unlockWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Biometric unlock requires a prior successful login session
    final token = _storage.getToken();
    if (token == null || _currentUser == null) {
      _errorMessage = 'Please log in with your credentials first before using biometric unlock.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        _errorMessage = 'Biometric hardware sensor unavailable on this device.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or Face ID to unlock Project PARAKH',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Verify the stored token is still valid on the backend
        final isValid = await validateSession();
        if (!isValid) {
          _errorMessage = 'Session expired. Please log in with your credentials again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Biometric authentication failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    _isSessionValidated = false;
    await _storage.clearAuth();
    notifyListeners();
  }
}
