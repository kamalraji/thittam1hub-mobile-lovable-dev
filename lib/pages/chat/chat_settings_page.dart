import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/settings_components.dart';

/// Enhanced Chat Settings page with search, animations, and new features
class ChatSettingsPage extends StatefulWidget {
  final String? channelId;
  final String? channelName;
  final bool isDM;

  const ChatSettingsPage({
    super.key,
    this.channelId,
    this.channelName,
    this.isDM = false,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage>
    with TickerProviderStateMixin {
  // Search
  String _searchQuery = '';

  // Per-chat notification settings
  bool _muteNotifications = false;
  String _muteUntil = 'Off';
  bool _customSound = false;
  String _selectedSound = 'Default';
  bool _vibrate = true;
  bool _showPreviews = true;

  // Chat theme settings
  String _selectedTheme = 'default';
  Color _accentColor = const Color(0xFF8B5CF6);
  double _fontSize = 16.0;
  bool _reducedMotion = false;
  String _bubbleStyle = 'modern';

  // Backup settings
  bool _autoBackup = false;
  String _backupFrequency = 'Weekly';
  bool _includeMedia = true;
  DateTime? _lastBackup;

  // Security & Privacy
  bool _endToEndEncryption = true;
  bool _screenshotNotify = false;
  bool _hideTypingIndicator = false;
  bool _hideReadReceipts = false;

  // Accessibility
  bool _highContrast = false;
  bool _largerTouchTargets = false;
  bool _screenReaderOptimized = false;

  // Storage stats (would load from service)
  final double _storageUsed = 45.2;
  final double _storageTotal = 100.0;
  final Map<String, double> _storageBreakdown = {
    'Images': 32.0,
    'Videos': 10.0,
    'Files': 3.2,
  };

  final List<Color> _themeColors = [
    const Color(0xFF8B5CF6), // Purple (brand)
    const Color(0xFF06B6D4), // Cyan (accent)
    const Color(0xFFEC4899), // Pink
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFF22C55E), // Green
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF6366F1), // Indigo
  ];

  final List<String> _muteDurations = [
    'Off',
    '1 hour',
    '8 hours',
    '1 day',
    '1 week',
    'Forever',
  ];

  final List<String> _soundOptions = [
    'Default',
    'Chime',
    'Bell',
    'Pop',
    'Swoosh',
    'None',
  ];

  final List<String> _backupFrequencies = ['Daily', 'Weekly', 'Monthly', 'Never'];
  final List<String> _themeOptions = ['default', 'minimal', 'gradient', 'classic'];
  final List<String> _bubbleStyles = ['modern', 'rounded', 'classic', 'flat'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.channelId != null ? 'Chat Settings' : 'Chat Preferences'),
        actions: [
          if (widget.channelId != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showChatInfo(context),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SettingsSearchBar(
                  onChanged: (query) => setState(() => _searchQuery = query),
                  hintText: 'Search settings...',
                ),
              ),
            ),

            // Per-chat header
            if (widget.channelId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _ChatHeader(
                    channelName: widget.channelName ?? 'Chat',
                    isDM: widget.isDM,
                  ),
                ),
              ),

            // Settings sections
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Actions
                  if (_matchesSearch('quick actions shortcuts'))
                    _buildQuickActions(cs),

                  const SizedBox(height: AppSpacing.md),

                  // Notifications Section
                  if (_matchesSearch('notifications mute sound vibrate preview'))
                    _buildNotificationsSection(),

                  const SizedBox(height: AppSpacing.md),

                  // Chat Theme Section
                  if (_matchesSearch('theme background color accent bubble font'))
                    _buildThemeSection(),

                  const SizedBox(height: AppSpacing.md),

                  // Security & Privacy Section
                  if (_matchesSearch('security privacy encryption screenshot typing receipts'))
                    _buildSecuritySection(),

                  const SizedBox(height: AppSpacing.md),

                  // Accessibility Section
                  if (_matchesSearch('accessibility contrast touch screen reader'))
                    _buildAccessibilitySection(),

                  const SizedBox(height: AppSpacing.md),

                  // Backup Section
                  if (_matchesSearch('backup restore export frequency media'))
                    _buildBackupSection(),

                  const SizedBox(height: AppSpacing.md),

                  // Media & Storage Section
                  if (_matchesSearch('media storage clear download images videos'))
                    _buildStorageSection(),

                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme cs) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, size: 18, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'QUICK ACTIONS',
                  style: context.textStyles.labelSmall?.withColor(cs.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _QuickActionChip(
                  icon: Icons.notifications_off,
                  label: 'Mute',
                  isActive: _muteUntil != 'Off',
                  onTap: () => setState(() {
                    _muteUntil = _muteUntil == 'Off' ? '1 hour' : 'Off';
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickActionChip(
                  icon: Icons.backup,
                  label: 'Backup',
                  isActive: false,
                  onTap: _backupNow,
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickActionChip(
                  icon: Icons.delete_sweep,
                  label: 'Clear Cache',
                  isActive: false,
                  onTap: _clearMedia,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return SettingsSection(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      iconColor: AppColors.violet500,
      children: [
        SettingsPicker<String>(
          label: 'Mute Notifications',
          subtitle: _muteUntil == 'Off' ? 'Notifications enabled' : 'Muted for $_muteUntil',
          icon: Icons.notifications_off_outlined,
          value: _muteUntil,
          options: _muteDurations,
          displayValue: (v) => v,
          onChanged: (v) => setState(() => _muteUntil = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Custom Sound',
          subtitle: 'Use a different notification sound',
          icon: Icons.music_note_outlined,
          value: _customSound,
          onChanged: (v) => setState(() => _customSound = v),
        ),
        if (_customSound) ...[
          const SettingsDivider(),
          SettingsPicker<String>(
            label: 'Notification Sound',
            icon: Icons.volume_up_outlined,
            value: _selectedSound,
            options: _soundOptions,
            displayValue: (v) => v,
            onChanged: (v) => setState(() => _selectedSound = v),
          ),
        ],
        const SettingsDivider(),
        SettingsToggle(
          label: 'Vibrate',
          subtitle: 'Vibrate on new messages',
          icon: Icons.vibration,
          value: _vibrate,
          onChanged: (v) => setState(() => _vibrate = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Show Message Previews',
          subtitle: 'Show message content in notifications',
          icon: Icons.preview,
          value: _showPreviews,
          onChanged: (v) => setState(() => _showPreviews = v),
        ),
      ],
    );
  }

  Widget _buildThemeSection() {
    return SettingsSection(
      title: 'Chat Theme',
      icon: Icons.palette_outlined,
      iconColor: AppColors.pink500,
      children: [
        _ThemeSelector(
          selectedTheme: _selectedTheme,
          themes: _themeOptions,
          onChanged: (v) => setState(() => _selectedTheme = v),
        ),
        const SettingsDivider(),
        SettingsColorPicker(
          label: 'Accent Color',
          selectedColor: _accentColor,
          colors: _themeColors,
          onChanged: (c) => setState(() => _accentColor = c),
        ),
        const SettingsDivider(),
        _BubbleStyleSelector(
          value: _bubbleStyle,
          styles: _bubbleStyles,
          onChanged: (v) => setState(() => _bubbleStyle = v),
        ),
        const SettingsDivider(),
        SettingsSlider(
          label: 'Message Font Size',
          icon: Icons.text_fields,
          value: _fontSize,
          min: 12,
          max: 24,
          divisions: 6,
          valueLabel: (v) => '${v.toInt()}px',
          onChanged: (v) => setState(() => _fontSize = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Reduced Motion',
          subtitle: 'Minimize animations in chat',
          icon: Icons.slow_motion_video,
          value: _reducedMotion,
          onChanged: (v) => setState(() => _reducedMotion = v),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return SettingsSection(
      title: 'Security & Privacy',
      icon: Icons.security_outlined,
      iconColor: AppColors.emerald500,
      initiallyExpanded: false,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.emerald500.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          'NEW',
          style: context.textStyles.labelSmall?.semiBold.withColor(AppColors.emerald500),
        ),
      ),
      children: [
        SettingsInfo(
          label: 'Encryption',
          value: 'End-to-End',
          icon: Icons.lock_outline,
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Screenshot Notifications',
          subtitle: 'Notify when someone takes a screenshot',
          icon: Icons.screenshot_outlined,
          value: _screenshotNotify,
          onChanged: (v) => setState(() => _screenshotNotify = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Hide Typing Indicator',
          subtitle: "Others won't see when you're typing",
          icon: Icons.keyboard_hide,
          value: _hideTypingIndicator,
          onChanged: (v) => setState(() => _hideTypingIndicator = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Hide Read Receipts',
          subtitle: "Others won't see when you've read messages",
          icon: Icons.done_all,
          value: _hideReadReceipts,
          onChanged: (v) => setState(() => _hideReadReceipts = v),
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'Block User',
          subtitle: 'Prevent this user from contacting you',
          icon: Icons.block,
          isDestructive: true,
          onTap: () => _showBlockConfirmation(),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection() {
    return SettingsSection(
      title: 'Accessibility',
      icon: Icons.accessibility_new,
      iconColor: AppColors.amber500,
      initiallyExpanded: false,
      children: [
        SettingsToggle(
          label: 'High Contrast Mode',
          subtitle: 'Increase text and UI contrast',
          icon: Icons.contrast,
          value: _highContrast,
          onChanged: (v) => setState(() => _highContrast = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Larger Touch Targets',
          subtitle: 'Make buttons and links easier to tap',
          icon: Icons.touch_app,
          value: _largerTouchTargets,
          onChanged: (v) => setState(() => _largerTouchTargets = v),
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Screen Reader Optimized',
          subtitle: 'Improve compatibility with screen readers',
          icon: Icons.record_voice_over,
          value: _screenReaderOptimized,
          onChanged: (v) => setState(() => _screenReaderOptimized = v),
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return SettingsSection(
      title: 'Message Backup',
      icon: Icons.cloud_outlined,
      iconColor: AppColors.teal500,
      children: [
        SettingsToggle(
          label: 'Auto Backup',
          subtitle: 'Automatically backup chat messages',
          icon: Icons.cloud_upload_outlined,
          value: _autoBackup,
          onChanged: (v) => setState(() => _autoBackup = v),
        ),
        if (_autoBackup) ...[
          const SettingsDivider(),
          SettingsPicker<String>(
            label: 'Backup Frequency',
            icon: Icons.schedule,
            value: _backupFrequency,
            options: _backupFrequencies,
            displayValue: (v) => v,
            onChanged: (v) => setState(() => _backupFrequency = v),
          ),
          const SettingsDivider(),
          SettingsToggle(
            label: 'Include Media',
            subtitle: 'Backup images and files',
            icon: Icons.photo_library_outlined,
            value: _includeMedia,
            onChanged: (v) => setState(() => _includeMedia = v),
          ),
        ],
        const SettingsDivider(),
        _BackupActionsRow(
          lastBackup: _lastBackup,
          onBackupNow: _backupNow,
          onRestore: _restoreBackup,
          onExport: _exportChat,
        ),
      ],
    );
  }

  Widget _buildStorageSection() {
    return SettingsSection(
      title: 'Media & Storage',
      icon: Icons.photo_library_outlined,
      iconColor: AppColors.indigo500,
      children: [
        _StorageVisualization(
          used: _storageUsed,
          total: _storageTotal,
          breakdown: _storageBreakdown,
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'Clear Media Cache',
          subtitle: 'Remove cached images and files',
          icon: Icons.delete_outline,
          onTap: _clearMedia,
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'Download All Media',
          subtitle: 'Save all shared media to device',
          icon: Icons.download,
          onTap: _downloadAllMedia,
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'View Media Gallery',
          subtitle: 'Browse all shared photos and videos',
          icon: Icons.collections,
          onTap: () => _showMediaGallery(),
        ),
      ],
    );
  }

  void _showChatInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Chat Information',
                style: context.textStyles.titleLarge?.semiBold,
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SettingsInfo(label: 'Created', value: 'Jan 15, 2024'),
                  SettingsInfo(label: 'Messages', value: '1,234'),
                  SettingsInfo(label: 'Media Files', value: '56'),
                  SettingsInfo(label: 'Storage Used', value: '45.2 MB'),
                  SettingsInfo(label: 'Participants', value: widget.isDM ? '2' : 'Group'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupNow() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backing up chat...')),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _lastBackup = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup complete!')),
      );
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will restore messages from your last backup. Current messages will be merged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring backup...')),
      );
    }
  }

  Future<void> _exportChat() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting chat history...')),
    );
  }

  Future<void> _clearMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Media Cache'),
        content: const Text(
          'This will remove all cached images and files. You can download them again if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media cache cleared!')),
      );
    }
  }

  Future<void> _downloadAllMedia() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading all media...')),
    );
  }

  void _showMediaGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening media gallery...')),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? They will not be able to send you messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked')),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

// ============ Helper Widgets ============

class _ChatHeader extends StatelessWidget {
  final String channelName;
  final bool isDM;

  const _ChatHeader({required this.channelName, required this.isDM});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.1),
            cs.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isDM ? Icons.person : Icons.group,
              color: cs.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelName,
                  style: context.textStyles.titleMedium?.semiBold,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDM ? 'Direct Message' : 'Group Chat',
                      style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.05),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? cs.primary.withOpacity(0.15)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.isActive ? cs.primary : cs.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: context.textStyles.labelMedium?.copyWith(
                  color: widget.isActive ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final String selectedTheme;
  final List<String> themes;
  final ValueChanged<String> onChanged;

  const _ThemeSelector({
    required this.selectedTheme,
    required this.themes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chat Background', style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: themes.map((theme) {
              final isSelected = theme == selectedTheme;
              return ChoiceChip(
                label: Text(theme.capitalize()),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onChanged(theme);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BubbleStyleSelector extends StatelessWidget {
  final String value;
  final List<String> styles;
  final ValueChanged<String> onChanged;

  const _BubbleStyleSelector({
    required this.value,
    required this.styles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bubble Style', style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: styles.map((style) {
              final isSelected = style == value;
              return ChoiceChip(
                label: Text(style.capitalize()),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onChanged(style);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BackupActionsRow extends StatelessWidget {
  final DateTime? lastBackup;
  final VoidCallback onBackupNow;
  final VoidCallback onRestore;
  final VoidCallback onExport;

  const _BackupActionsRow({
    required this.lastBackup,
    required this.onBackupNow,
    required this.onRestore,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastBackup != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Last backup: ${_formatDate(lastBackup!)}',
                    style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: onBackupNow,
                icon: const Icon(Icons.backup, size: 18),
                label: const Text('Backup Now'),
              ),
              OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Restore'),
              ),
              TextButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StorageVisualization extends StatelessWidget {
  final double used;
  final double total;
  final Map<String, double> breakdown;

  const _StorageVisualization({
    required this.used,
    required this.total,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      AppColors.indigo500,
      AppColors.violet500,
      AppColors.amber500,
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage Used', style: context.textStyles.bodyMedium),
              Text(
                '${used.toStringAsFixed(1)} MB',
                style: context.textStyles.bodyMedium?.semiBold.withColor(cs.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  ...breakdown.entries.toList().asMap().entries.map((entry) {
                    final ratio = entry.value.value / total;
                    return Expanded(
                      flex: (ratio * 100).toInt(),
                      child: Container(color: colors[entry.key % colors.length]),
                    );
                  }),
                  Expanded(
                    flex: ((total - used) / total * 100).toInt(),
                    child: Container(color: cs.surfaceContainerHighest),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: breakdown.entries.toList().asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[entry.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.value.key}: ${entry.value.value.toStringAsFixed(1)} MB',
                    style: context.textStyles.labelSmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// String extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
