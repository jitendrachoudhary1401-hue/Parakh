import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/compliance_provider.dart';
import '../widgets/status_pill.dart';

/// Inspection History Ledger Screen (Searchable and filterable)
class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  String _filter = 'ALL'; // ALL, PASS, VIOLATION
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final compliance = Provider.of<ComplianceProvider>(context);
    final history = compliance.inspectionHistory.where((item) {
      if (_filter == 'PASS' && !item.isCompliant) return false;
      if (_filter == 'VIOLATION' && item.isCompliant) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return item.productName.toLowerCase().contains(query) ||
            item.storeName.toLowerCase().contains(query) ||
            item.barcode.contains(query) ||
            item.id.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inspection Ledger'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(AppTheme.marginMain),
              color: AppTheme.surface,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search by Product, GTIN, Store, or ID...',
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: AppTheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFilterChip('ALL',
                          'All Scans (${compliance.inspectionHistory.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('PASS', 'Compliant'),
                      const SizedBox(width: 8),
                      _buildFilterChip('VIOLATION', 'Violations'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Ledger List
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_outlined,
                              size: 40, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text('No inspection records match the filter',
                              style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.marginMain),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _buildLedgerCard(context, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerCard(BuildContext context, InspectionRecord item) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);

    return InkWell(
      onTap: () {
        compliance.evaluateCompliance(
          extracted: item.extractedData,
          gs1: GS1Product(
            gtin: item.barcode,
            productName: item.productName,
            registeredCompany: 'Registered Manufacturer',
            companyAddress: item.locationAddress,
            brand: 'Standard Brand',
            isVerified: true,
          ),
          storeName: item.storeName,
          locationAddress: item.locationAddress,
        );
        Navigator.pushNamed(context, '/evidence-report');
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.outline),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.id,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: AppTheme.primary),
              ),
              StatusPill(
                label: item.isCompliant ? 'COMPLIANT' : 'VIOLATION',
                isCompliant: item.isCompliant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.productName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.storefront, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code,
                      size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('GTIN: ${item.barcode}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.textMuted)),
                ],
              ),
              Text(dateStr,
                  style:
                      const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
          if (item.blockchainReceipt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 11, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tx: ${item.blockchainReceipt!.txHash.substring(0, 28)}...',
                      style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
