import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/pharmacy_service.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isOpen = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final pharmacy = await _pharmacyService.getPharmacyDetails('me');
      if (mounted) setState(() => _isOpen = pharmacy.isOpen);
    } catch (_) {}
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() { _isUpdating = true; _isOpen = value; });
    try {
      await _pharmacyService.toggleOpenStatus(value);
    } catch (_) {
      if (mounted) setState(() => _isOpen = !value);
    }
    if (mounted) setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Pharmacy Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF009B7D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.local_pharmacy_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Pharmacy',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Open/Close toggle
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOpen
                              ? Icons.storefront_rounded
                              : Icons.store_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isOpen ? 'Open for Orders' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_isUpdating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Switch(
                            value: _isOpen,
                            onChanged: _toggleStatus,
                            activeColor: Colors.white,
                            activeTrackColor: AppTheme.successGreen,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Items
            _buildSection('Store Settings', [
              _MenuItem(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle: 'Update pharmacy details',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.access_time_rounded,
                title: 'Operating Hours',
                subtitle: 'Set open/close timings',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.delivery_dining_rounded,
                title: 'Delivery Settings',
                subtitle: 'Radius, fee, minimum order',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.payments_rounded,
                title: 'Payment Settings',
                subtitle: 'UPI, bank account details',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 20),

            _buildSection('Notifications & Support', [
              _MenuItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Order alerts, stock alerts',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'FAQs, contact support',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Policies',
                subtitle: 'Legal information',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 20),

            _buildSection('Account', [
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                isDestructive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorRed),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (_) => false);
                    }
                  }
                },
              ),
            ]),
            const SizedBox(height: 40),

            // App version
            const Center(
              child: Text(
                'Flash Pharma Pharmacy v1.0.0',
                style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      item.icon,
                      color: item.isDestructive
                          ? AppTheme.errorRed
                          : AppTheme.primaryGreen,
                      size: 22,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: item.isDestructive
                            ? AppTheme.errorRed
                            : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textHint),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: item.isDestructive
                          ? AppTheme.errorRed
                          : AppTheme.textHint,
                      size: 20,
                    ),
                    onTap: item.onTap,
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}
