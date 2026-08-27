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
  int _syncedCount = 0;

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
    notifyListeners();
  }

  void toggleNetworkConnectivity(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  /// Add an inspection to the offline queue
  Future<void> queueInspection(InspectionRecord record, String localImagePath) async {
    final item = SyncQueueItem(
      id: 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
      inspectionId: record.id,
      localImagePath: localImagePath,
      barcode: record.barcode,
      storeName: record.storeName,
      createdAt: DateTime.now(),
      status: 'pending',
    );
    await _storage.addToSyncQueue(item);
    _loadQueue();
  }

  /// Trigger sync of offline queue
  Future<void> syncAllPending() async {
    if (_queue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> recordsPayload = [];
      final List<InspectionRecord> localInspections = _storage.getInspections();

      for (final item in _queue) {
        final match = localInspections.firstWhere(
          (r) => r.id == item.inspectionId,
          orElse: () => InspectionRecord(
            id: item.inspectionId,
            barcode: item.barcode,
            productName: 'Offline Item',
            storeName: item.storeName,
            locationAddress: 'Offline Location',
            latitude: 28.6139,
            longitude: 77.2090,
            timestamp: item.createdAt,
            isCompliant: true,
            imagePath: item.localImagePath,
            extractedData: OCRExtractedData.empty(),
            violations: [],
          ),
        );

        recordsPayload.add({
          'client_inspection_id': match.id,
          'product_barcode': match.barcode,
          'latitude': match.latitude,
          'longitude': match.longitude,
          'location_name': match.locationAddress,
          'notes': match.storeName,
          'client_timestamp': match.timestamp.toIso8601String(),
        });
      }

      final response = await _apiClient.post(
        '/sync/upload',
        body: {'records': recordsPayload},
      );

      if (response.success && response.data != null) {
        // Mark matched records in local storage as synced
        for (final item in _queue) {
          final idx = localInspections.indexWhere((r) => r.id == item.inspectionId);
          if (idx >= 0) {
            final old = localInspections[idx];
            final updated = InspectionRecord(
              id: old.id,
              barcode: old.barcode,
              productName: old.productName,
              storeName: old.storeName,
              locationAddress: old.locationAddress,
              latitude: old.latitude,
              longitude: old.longitude,
              timestamp: old.timestamp,
              isCompliant: old.isCompliant,
              imagePath: old.imagePath,
              extractedData: old.extractedData,
              violations: old.violations,
              blockchainReceipt: old.blockchainReceipt,
              legalNoticePdfUrl: old.legalNoticePdfUrl,
              isSynced: true,
            );
            await _storage.saveInspection(updated);
          }
          await _storage.removeSyncQueueItem(item.id);
        }

        final count = (response.data!['synced_count'] as num?)?.toInt() ?? _queue.length;
        _syncedCount += count;
        _queue.clear();
      }
    } catch (_) {
      // Keep items in the queue on failure
    } finally {
      _isSyncing = false;
      _loadQueue();
    }
  }

  Future<void> removeQueueItem(String id) async {
    _queue.removeWhere((item) => item.id == id);
    await _storage.removeSyncQueueItem(id);
    notifyListeners();
  }
}
