import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/compliance_provider.dart';
import '../widgets/status_pill.dart';

/// Compliance Verdict Screen (Pass/Fail Rule Breakdown)
class ComplianceVerdictScreen extends StatelessWidget {
  const ComplianceVerdictScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compliance = Provider.of<ComplianceProvider>(context);
    final record = compliance.currentInspection;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compliance Verdict')),
        body: const Center(child: Text('No active inspection record')),
      );
    }

    final isPassed = record.isCompliant;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Compliance Verdict'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Verdict Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPassed ? AppTheme.success : AppTheme.error,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  children: [
                    Icon(
                      isPassed ? Icons.verified_outlined : Icons.gavel_outlined,
                      size: 44,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPassed ? 'COMPLIANT WITH LEGAL METROLOGY' : 'NON-COMPLIANCE VIOLATION DETECTED',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPassed
                          ? 'All declarations satisfy the Packaged Commodities Rules, 2011.'
                          : '${record.violations.length} mandatory declaration rule(s) violated.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product Info Card
              Container(
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
                          'INSPECTION ID: ${record.id}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        StatusPill(
                          label: isPassed ? 'PASS' : 'VIOLATION',
                          isCompliant: isPassed,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      record.productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.storeName} • ${record.locationAddress}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rules Evaluation Breakdown
              Text(
                'LEGAL METROLOGY 2011 RULES EVALUATION',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),

              _buildRuleCheckCard(
                title: 'Rule 6(1)(e): MRP Format & Inclusion of Taxes',
                isPassed: true,
                note: 'Verified "₹ 45.00 (Incl. of all taxes)"',
              ),
              const SizedBox(height: 8),

              _buildRuleCheckCard(
                title: 'Rule 6(1)(f): Net Quantity Unit Declarations',
                isPassed: true,
                note: 'Verified "200 g" standard unit & minimum font size',
              ),
              const SizedBox(height: 8),

              _buildRuleCheckCard(
                title: 'Rule 6(1)(d): Month & Year of Mfg/Packing',
                isPassed: true,
                note: 'Verified "04/2026"',
              ),
              const SizedBox(height: 8),

              _buildRuleCheckCard(
                title: 'Rule 6(1)(h): Mandatory Consumer Care Contact',
                isPassed: isPassed,
                note: isPassed
                    ? 'Verified Phone (1800-11-2026) & Email (care@hindustanfoods.in)'
                    : 'Rule Violation: Missing official Consumer Care email address for grievance redressal.',
              ),
              const SizedBox(height: 8),

              _buildRuleCheckCard(
                title: 'Rule 6(1)(a): Manufacturer Registry & GS1',
                isPassed: true,
                note: 'GTIN 8901030382910 matches registered manufacturer record',
              ),
              const SizedBox(height: 24),

              if (!isPassed) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  onPressed: () => Navigator.pushNamed(context, '/evidence-report'),
                  icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                  label: const Text('GENERATE BLOCKCHAIN EVIDENCE & NOTICE'),
                ),
                const SizedBox(height: 10),
              ],

              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                child: const Text('LOG TO LOCAL LEDGER & RETURN TO DASHBOARD'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCheckCard({
    required String title,
    required bool isPassed,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isPassed ? AppTheme.outline : AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPassed ? Icons.check_circle_outline : Icons.highlight_off,
            size: 20,
            color: isPassed ? AppTheme.success : AppTheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPassed ? AppTheme.textPrimary : AppTheme.error,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
