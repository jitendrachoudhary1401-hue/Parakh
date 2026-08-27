import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/models.dart';

/// Sync Provider managing Offline Queues, Background Uploads, and Diagnostic Connectivity
class SyncProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  ApiClient get apiClient => _apiClient;

  List<SyncQueueItem> _queue = [];
  bool _isSyncing = false;
  bool _isOnline = true;
  int _syncedCount = 14;

  SyncProvider(this._apiClient, this._storage) {
    _loadQueue();
  }

  List<SyncQueueItem> get queue => _queue;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get syncedCount => _syncedCount;
  int get pendingCount => _queue.length;

  void _loadQueue() {
    _queue = _storage.getSyncQueue();
    if (_queue.isEmpty) {
      _queue = [
        SyncQueueItem(
          id: 'sync_q_01',
          inspectionId: 'INSP-2026-OFFLINE-01',
          localImagePath: 'cache/scan_raw_8901.jpg',
          barcode: '8901030382910',
          storeName: 'Basement Grocery Mart, Connaught Place',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          retryCount: 1,
          status: 'pending',
        ),
        SyncQueueItem(
          id: 'sync_q_02',
          inspectionId: 'INSP-2026-OFFLINE-02',
          localImagePath: 'cache/scan_raw_8902.jpg',
          barcode: '8902049102938',
          storeName: 'Rural Mandi Warehouse, Mehrauli',
          createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
          retryCount: 0,
          status: 'pending',
        ),
      ];
    }
    notifyListeners();
  }

  void toggleNetworkConnectivity(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  /// Trigger sync of offline queue
  Future<void> syncAllPending() async {
    if (_queue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    for (int i = 0; i < _queue.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    _syncedCount += _queue.length;
    _queue.clear();
    await _storage.saveInspection(InspectionRecord(
      id: 'INSP-2026-OFFLINE-01',
      barcode: '8901030382910',
      productName: 'Packaged Wheat Atta (10kg)',
      storeName: 'Basement Grocery Mart, Connaught Place',
      locationAddress: 'Connaught Place, New Delhi',
      latitude: 28.6315,
      longitude: 77.2167,
      timestamp: DateTime.now(),
      isCompliant: true,
      imagePath: '',
      extractedData: OCRExtractedData.empty(),
      violations: [],
      isSynced: true,
    ));

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> removeQueueItem(String id) async {
    _queue.removeWhere((item) => item.id == id);
    await _storage.removeSyncQueueItem(id);
    notifyListeners();
  }
}
