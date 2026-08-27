import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Local Storage Service for Offline Inspections, Token, and Settings
class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyInspections = 'local_inspections';
  static const String _keySyncQueue = 'sync_queue';
  static const String _keyLanguage = 'selected_language';
  static const String _keyApiUrl = 'custom_api_url';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Auth Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
  }

  // User Profile
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final str = _prefs.getString(_keyUser);
    if (str == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  // Inspections History (Local Cache + Offline drafts)
  Future<void> saveInspection(InspectionRecord record) async {
    final list = getInspections();
    final index = list.indexWhere((e) => e.id == record.id);
    if (index >= 0) {
      list[index] = record;
    } else {
      list.insert(0, record);
    }
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyInspections, encoded);
  }

  List<InspectionRecord> getInspections() {
    final str = _prefs.getString(_keyInspections);
    if (str == null) return [];
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => InspectionRecord.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Offline Sync Queue
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    final queue = getSyncQueue();
    queue.add(item);
    await _prefs.setString(_keySyncQueue, jsonEncode(queue.map((e) => e.toJson()).toList()));
  }

  List<SyncQueueItem> getSyncQueue() {
    final str = _prefs.getString(_keySyncQueue);
    if (str == null) return [];
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => SyncQueueItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> removeSyncQueueItem(String id) async {
    final queue = getSyncQueue();
    queue.removeWhere((e) => e.id == id);
    await _prefs.setString(_keySyncQueue, jsonEncode(queue.map((e) => e.toJson()).toList()));
  }

  // Language & Settings
  Future<void> setLanguage(String lang) async => await _prefs.setString(_keyLanguage, lang);
  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'en';

  Future<void> setCustomApiUrl(String url) async => await _prefs.setString(_keyApiUrl, url);
  String? getCustomApiUrl() => _prefs.getString(_keyApiUrl);
}
