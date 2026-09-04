import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

/// Inspector Profile & App Settings Screen
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _selectedLanguage = 'English';
  late TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _serverUrlController = TextEditingController(text: auth.apiClient.baseUrl);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inspector Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inspector Identity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryContainer,
                      child: Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Inspector Rajesh Kumar',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Badge: ${user?.officialId ?? "DOCA-INSP-2026"}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppTheme.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.zone ?? 'North Zone (New Delhi Division)',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Role Authorization Badge Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Jurisdiction: ${(user?.role.name ?? "inspector").toUpperCase()}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'Statutory Legal Metrology (Packaged Commodities) Grid',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AUTHORIZED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Section
              Text(
                'PREFERENCES & LOCALIZATION',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.language,
                                size: 18, color: AppTheme.secondary),
                            SizedBox(width: 10),
                            Text('Language / भाषा',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        DropdownButton<String>(
                          value: _selectedLanguage,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                                value: 'English',
                                child: Text('English',
                                    style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguage = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.fingerprint,
                                size: 18, color: AppTheme.secondary),
                            SizedBox(width: 10),
                            Text('Biometric Field Unlock',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Switch(
                          value: true,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (val) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // API Gateway Server Config
              Text(
                'GATEWAY ROUTING & CONNECTIVITY',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),

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
                    const Text(
                      'FastAPI Gateway Server URL',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _serverUrlController,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'http://172.17.12.24:8000/api/v1',
                        prefixIcon: Icon(Icons.dns_outlined,
                            size: 18, color: AppTheme.secondary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        final newUrl = _serverUrlController.text.trim();
                        if (newUrl.isNotEmpty) {
                          auth.updateServerUrl(newUrl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Server Gateway URL updated to: $newUrl'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('UPDATE GATEWAY URL'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Connected to DoCA National Compliance Cloud (NIC MeghRaj)',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await auth.logout();
                  if (mounted) {
                    nav.pushReplacementNamed('/login');
                  }
                },
                icon: const Icon(Icons.logout, size: 18, color: AppTheme.error),
                label: const Text('LOGOUT OF ENFORCEMENT PORTAL'),
              ),
              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Project PARAKH Mobile v1.0.0 • DoCA PS-26034',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
