import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/scan_provider.dart';

/// Step 1: Establishment Intake Screen
/// Asks Inspector for Shop Name, Shop Owner Name, and Address of Shop prior to scanning.
class EstablishmentIntakeScreen extends StatefulWidget {
  const EstablishmentIntakeScreen({super.key});

  @override
  State<EstablishmentIntakeScreen> createState() =>
      _EstablishmentIntakeScreenState();
}

class _EstablishmentIntakeScreenState extends State<EstablishmentIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopOwnerController = TextEditingController();
  final _shopAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = Provider.of<ScanProvider>(context, listen: false);
      // Pre-fill if already set in provider
      if (scan.shopName.isNotEmpty) _shopNameController.text = scan.shopName;
      if (scan.shopOwnerName.isNotEmpty) {
        _shopOwnerController.text = scan.shopOwnerName;
      }
      if (scan.shopAddress.isNotEmpty) {
        _shopAddressController.text = scan.shopAddress;
      }

      // Request live location if not acquired
      scan.fetchCurrentLocation(requestIfDenied: true);
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopOwnerController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  void _handleProceedToScan() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all mandatory establishment details.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final scan = Provider.of<ScanProvider>(context, listen: false);

    // If GPS is disabled, prompt user to turn it on before proceeding
    if (scan.isGpsServiceDisabled) {
      _showGpsTurnOnDialog(scan);
      return;
    }

    scan.setEstablishmentDetails(
      name: _shopNameController.text.trim(),
      owner: _shopOwnerController.text.trim(),
      address: _shopAddressController.text.trim(),
    );

    Navigator.pushNamed(context, '/barcode-scanner');
  }

  void _showGpsTurnOnDialog(ScanProvider scan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.location_off, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Turn On Device GPS', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Location services are currently turned OFF on your device.\n\n'
          'Under statutory Legal Metrology rules, inspections require high-accuracy Fused GPS geotagging (combining GPS satellites, Wi-Fi, and cell tower data).\n\n'
          'Please turn on device location to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.settings),
            label: const Text('Turn On Location'),
            onPressed: () {
              Navigator.pop(ctx);
              scan.openGpsSettings();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Establishment Intake'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Process Stepper Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'STEP 1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Record Establishment Details prior to packaging scanning.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GPS / Fused Location Status Banner
                if (scan.isGpsServiceDisabled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded,
                                color: AppTheme.error, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Device GPS is Turned OFF',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fused Location combines GPS satellites, Wi-Fi networks, and cell towers for accurate statutory evidence.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(36),
                          ),
                          icon: const Icon(Icons.location_on, size: 16),
                          label: const Text('TURN ON GPS / LOCATION SERVICES'),
                          onPressed: () => scan.openGpsSettings(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          scan.currentLocation != null
                              ? Icons.my_location
                              : Icons.location_searching,
                          color: scan.currentLocation != null
                              ? AppTheme.success
                              : AppTheme.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.currentLocation != null
                                    ? 'High-Accuracy Fused GPS Locked'
                                    : 'Acquiring Fused Location...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scan.currentLocation != null
                                      ? AppTheme.success
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                scan.locationAddress,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: 'Refresh GPS',
                          onPressed: () =>
                              scan.fetchCurrentLocation(requestIfDenied: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Shop / Establishment Details Form Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMMERCIAL PREMISES & PROPRIETOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Shop Name
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop / Establishment Name *',
                          hintText: 'e.g. Modern Retail Mart or Sharma Kirana Store',
                          prefixIcon: Icon(Icons.storefront_outlined),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the commercial establishment name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Shop Owner Name
                      TextFormField(
                        controller: _shopOwnerController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Owner / Proprietor Name *',
                          hintText: 'e.g. Shri Ramesh Kumar Gupta',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the proprietor / owner name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Shop Address
                      TextFormField(
                        controller: _shopAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Complete Shop Address & Landmark *',
                          hintText: 'e.g. Shop No. 12, Main Market, Sector 18, Noida, UP',
                          prefixIcon: Icon(Icons.pin_drop_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the full physical premise address.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button: Proceed to Scanning
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  onPressed: _handleProceedToScan,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'PROCEED TO PRODUCT BARCODE SCAN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
