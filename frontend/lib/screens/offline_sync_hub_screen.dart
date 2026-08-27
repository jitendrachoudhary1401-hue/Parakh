import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/sync_provider.dart';

/// Offline Sync Hub Screen (Pending queue & background upload manager)
class OfflineSyncHubScreen extends StatelessWidget {
  const OfflineSyncHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Offline Sync Hub'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connectivity Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sync.isOnline
                      ? AppTheme.successContainer
                      : AppTheme.warningContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color: sync.isOnline
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      sync.isOnline ? Icons.wifi : Icons.wifi_off,
                      color:
                          sync.isOnline ? AppTheme.success : AppTheme.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sync.isOnline
                                ? 'ONLINE & SYNC READY'
                                : 'OFFLINE MODE (LOCAL BUFFER)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: sync.isOnline
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sync.isOnline
                                ? 'FastAPI Gateway reachable at ${sync.syncedCount} scans anchored'
                                : 'Operating in low-connectivity retail basement. Scans buffered locally.',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Queue Summary Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox('Pending Uploads',
                        '${sync.pendingCount}', AppTheme.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryBox('Synced Scans',
                        '${sync.syncedCount}', AppTheme.success),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pending Upload List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PENDING FIELD SCANS QUEUE',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (sync.pendingCount > 0)
                    Text(
                      '${sync.pendingCount} Items',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (sync.queue.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.cloud_done_outlined,
                            size: 36, color: AppTheme.success),
                        SizedBox(height: 8),
                        Text('All field scans are completely synchronized',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sync.queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = sync.queue[index];
                    return _buildQueueItemCard(context, item, sync);
                  },
                ),
              const SizedBox(height: 24),

              // Action Trigger
              ElevatedButton.icon(
                onPressed: (sync.isSyncing || sync.queue.isEmpty)
                    ? null
                    : () => sync.syncAllPending(),
                icon: sync.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync, size: 18),
                label: Text(sync.isSyncing
                    ? 'SYNCHRONIZING PENDING QUEUE...'
                    : 'SYNC ALL PENDING SCANS NOW'),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => sync.toggleNetworkConnectivity(!sync.isOnline),
                icon: Icon(
                    sync.isOnline
                        ? Icons.signal_cellular_off
                        : Icons.signal_cellular_alt,
                    size: 18),
                label: Text(sync.isOnline
                    ? 'SIMULATE RETAIL BASEMENT (OFFLINE)'
                    : 'SIMULATE NETWORK RESTORED (ONLINE)'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildQueueItemCard(
      BuildContext context, SyncQueueItem item, SyncProvider sync) {
    final dateStr = DateFormat('HH:mm, dd MMM').format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.image_outlined,
                size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.inspectionId,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text('Queued: $dateStr • GTIN: ${item.barcode}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppTheme.error),
            onPressed: () => sync.removeQueueItem(item.id),
          ),
        ],
      ),
    );
  }
}
