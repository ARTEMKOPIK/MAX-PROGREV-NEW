import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
              title: const Text('Русский'),
              onTap: () {
                ref.read(localeProvider.notifier).setRussian();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () {
                ref.read(localeProvider.notifier).setEnglish();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('profile'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? l10n.translate('username'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${user?.id ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    l10n.translate('accounts'),
                    '${user?.paidAccounts ?? 0}',
                    Icons.smartphone,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    l10n.translate('referrals'),
                    '${user?.referrals ?? 0}',
                    Icons.people,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.language,
              title: l10n.translate('language'),
              subtitle: currentLocale.languageCode == 'ru' ? 'Русский' : 'English',
              onTap: () => _showLanguageDialog(context, ref),
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.dark_mode,
              title: l10n.translate('theme'),
              subtitle: l10n.translate('system_default'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('theme_selection_soon'))),
                );
              },
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.notifications,
              title: l10n.translate('notifications'),
              subtitle: l10n.translate('manage_notifications'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('notification_settings_soon'))),
                );
              },
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.support_agent,
              title: l10n.translate('support'),
              subtitle: l10n.translate('get_help'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('support_coming_soon'))),
                );
              },
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.info,
              title: l10n.translate('about'),
              subtitle: l10n.translate('version'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: l10n.translate('app_name'),
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.water_drop_rounded, size: 48, color: AppTheme.primaryColor),
                  children: [
                    Text(
                      l10n.translate('app_subtitle'),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.translate('logout')),
                    content: Text(l10n.translate('are_you_sure_logout')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.translate('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: Text(l10n.translate('logout')),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.translate('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Atlantis Grev © 2024',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

