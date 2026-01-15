import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/services/theme_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/auth/supabase_auth_manager.dart';

/// Settings screen with account info, theme toggle, and notification preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _profileService = ProfileService();
  final _authManager = SupabaseAuthManager();
  
  NotificationPreferences? _prefs;
  String _userEmail = '';
  String _userRole = 'PARTICIPANT';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    final email = SupabaseConfig.auth.currentUser?.email;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await _profileService.getNotificationPreferences(userId);
      
      if (mounted) {
        setState(() {
          _prefs = prefs ?? NotificationPreferences(userId: userId);
          _userEmail = email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(NotificationPreferences newPrefs) async {
    setState(() => _prefs = newPrefs);
    try {
      await _profileService.updateNotificationPreferences(newPrefs);
    } catch (e) {
      debugPrint('Failed to update preferences: $e');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final cs = Theme.of(context).colorScheme;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _authManager.deleteUser(context);
        // User will be signed out automatically
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (_isLoading || _prefs == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Account Section
          _SectionCard(
            title: 'Account',
            children: [
              _InfoRow(label: 'Email', value: _userEmail),
              const Divider(height: 1),
              _InfoRow(
                label: 'Role',
                value: _userRole,
                badge: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Appearance Section (Theme Toggle)
          _SectionCard(
            title: 'Appearance',
            children: [
              _ThemeModeRow(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Become Organizer Banner (if PARTICIPANT)
          if (_userRole == 'PARTICIPANT') ...[
            Card(
              color: cs.secondary.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: cs.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Become an organizer',
                          style: context.textStyles.titleMedium?.semiBold,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Upgrade to create events and manage organizations',
                      style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upgrade flow coming soon')),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: cs.secondary),
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Notifications Section
          _SectionCard(
            title: 'Notifications',
            children: [
              _ToggleRow(
                label: 'Workspaces',
                subtitle: 'Task updates, mentions, invitations',
                value: _prefs!.workspaceEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(workspaceEnabled: value),
                ),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Events',
                subtitle: 'Event reminders and schedule changes',
                value: _prefs!.eventEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(eventEnabled: value),
                ),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Marketplace',
                subtitle: 'Booking updates and service messages',
                value: _prefs!.marketplaceEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(marketplaceEnabled: value),
                ),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Organizations',
                subtitle: 'Updates from organizations you follow',
                value: _prefs!.organizationEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(organizationEnabled: value),
                ),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'System',
                subtitle: 'Product updates and security alerts',
                value: _prefs!.systemEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(systemEnabled: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Sound & Haptics Section
          _SectionCard(
            title: 'Sound & Haptics',
            children: [
              _ToggleRow(
                label: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _prefs!.soundEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(soundEnabled: value),
                ),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Vibration',
                subtitle: 'Vibrate for critical alerts',
                value: _prefs!.vibrationEnabled,
                onChanged: (value) => _updatePreference(
                  _prefs!.copyWith(vibrationEnabled: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Danger Zone
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DANGER ZONE',
                    style: context.textStyles.labelSmall?.withColor(AppColors.error),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: _handleDeleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme mode selection row
class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeService = context.watch<ThemeService>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: ThemeMode.values.map((mode) {
              final isSelected = themeService.themeMode == mode;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: mode != ThemeMode.values.last ? AppSpacing.sm : 0,
                  ),
                  child: _ThemeOptionButton(
                    icon: themeService.getThemeModeIcon(mode),
                    label: themeService.getThemeModeDisplayName(mode),
                    isSelected: isSelected,
                    onTap: () => themeService.setThemeMode(mode),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Individual theme option button
class _ThemeOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section card wrapper
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// Info row (label + value)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool badge;

  const _InfoRow({
    required this.label,
    required this.value,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textStyles.bodyMedium),
          badge
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: context.textStyles.labelSmall?.semiBold.withColor(cs.primary),
                  ),
                )
              : Text(
                  value,
                  style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                ),
        ],
      ),
    );
  }
}

/// Toggle row with switch
class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
