import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
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
  final _serverUrlController =
      TextEditingController(text: AppConstants.defaultApiBaseUrl);

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
              const SizedBox(height: 20),

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
                            DropdownMenuItem(
                                value: 'Hindi',
                                child: Text('हिन्दी (Hindi)',
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
                        hintText: 'http://192.168.43.59:8000/api/v1',
                        prefixIcon: Icon(Icons.dns_outlined,
                            size: 18, color: AppTheme.secondary),
                      ),
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
