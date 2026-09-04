import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/parakh_logo.dart';

/// Secure Login Screen for Enforcement Officials
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officialIdController = TextEditingController(text: 'DOCA-FI-2026-0101');
  final _passwordController = TextEditingController(text: 'Inspector@2026');
  bool _obscurePassword = true;
  String _selectedRole = 'food_inspector';

  void _selectDemoAccount(String role, String uid, String password) {
    setState(() {
      _selectedRole = role;
      _officialIdController.text = uid;
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _officialIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      officialId: _officialIdController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _handleBiometric() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.unlockWithBiometrics();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.marginMain),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const ParakhLogo(
                    width: 140,
                    height: 75,
                    showText: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enforcement Officer Login',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Department of Consumer Affairs (DoCA) • National Compliance Grid',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SIH 2026 Role Selector
                  Text(
                    'SELECT OFFICIAL ROLE (SIH 2026)',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.shield_outlined, size: 16),
                          label: const Text('Food Inspector'),
                          selected: _selectedRole == 'food_inspector',
                          onSelected: (_) => _selectDemoAccount(
                            'food_inspector',
                            'DOCA-FI-2026-0101',
                            'Inspector@2026',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.gavel_outlined, size: 16),
                          label: const Text('Nodal Officer'),
                          selected: _selectedRole == 'nodal_officer',
                          onSelected: (_) => _selectDemoAccount(
                            'nodal_officer',
                            'DOCA-NO-2026-0202',
                            'Nodal@2026',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.account_balance_outlined, size: 16),
                          label: const Text('Commissioner'),
                          selected: _selectedRole == 'food_safety_commissioner',
                          onSelected: (_) => _selectDemoAccount(
                            'food_safety_commissioner',
                            'DOCA-FSC-2026-0303',
                            'Commissioner@2026',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Official ID Input
                  Text(
                    'OFFICIAL BADGE ID / EMAIL',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _officialIdController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. DOCA-FI-2026-0101',
                      prefixIcon: Icon(Icons.badge_outlined,
                          size: 20, color: AppTheme.secondary),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please enter Official Badge ID or Email'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  Text(
                    'OFFICIAL PASSWORD',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 20, color: AppTheme.secondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) => val == null || val.length < 4
                        ? 'Password must be at least 4 chars'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('AUTHENTICATE & ENTER FIELD PORTAL'),
                  ),
                  const SizedBox(height: 12),

                  // Biometric Button
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _handleBiometric,
                    icon: const Icon(Icons.fingerprint, size: 20),
                    label: const Text('QUICK FIELD BIOMETRIC UNLOCK'),
                  ),
                  const SizedBox(height: 28),

                  // Security Stamp
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user,
                          size: 14, color: AppTheme.success),
                      SizedBox(width: 6),
                      Text(
                        'Secured via AES-256 & TLS 1.3 Encryption',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
