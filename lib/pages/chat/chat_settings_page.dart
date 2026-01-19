import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/theme.dart';

/// Dedicated Chat Settings page with granular controls
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

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  // Per-chat notification settings
  bool _muteNotifications = false;
  String _muteUntil = 'Off';
  bool _customSound = false;
  String _selectedSound = 'Default';
  bool _vibrate = true;
  bool _showPreviews = true;
  
  // Chat theme settings
  String _selectedTheme = 'default';
  Color _accentColor = const Color(0xFF6366F1);
  double _fontSize = 16.0;
  bool _reducedMotion = false;
  String _bubbleStyle = 'modern';
  
  // Backup settings
  bool _autoBackup = false;
  String _backupFrequency = 'Weekly';
  bool _includeMedia = true;
  DateTime? _lastBackup;
  
  final List<Color> _themeColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFF22C55E), // Green
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
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
  
  final List<String> _backupFrequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Never',
  ];

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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Per-chat header (if specific chat)
          if (widget.channelId != null) ...[
            _ChatHeader(
              channelName: widget.channelName ?? 'Chat',
              isDM: widget.isDM,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          
          // Notifications Section
          _SectionCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            children: [
              _MuteRow(
                value: _muteUntil,
                options: _muteDurations,
                onChanged: (value) => setState(() => _muteUntil = value),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Custom Sound',
                subtitle: 'Use a different notification sound',
                value: _customSound,
                onChanged: (value) => setState(() => _customSound = value),
              ),
              if (_customSound) ...[
                const Divider(height: 1),
                _SoundSelector(
                  value: _selectedSound,
                  options: _soundOptions,
                  onChanged: (value) => setState(() => _selectedSound = value),
                ),
              ],
              const Divider(height: 1),
              _ToggleRow(
                label: 'Vibrate',
                subtitle: 'Vibrate on new messages',
                value: _vibrate,
                onChanged: (value) => setState(() => _vibrate = value),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Show Message Previews',
                subtitle: 'Show message content in notifications',
                value: _showPreviews,
                onChanged: (value) => setState(() => _showPreviews = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Chat Theme Section
          _SectionCard(
            title: 'Chat Theme',
            icon: Icons.palette_outlined,
            children: [
              _ThemeSelector(
                selectedTheme: _selectedTheme,
                onChanged: (value) => setState(() => _selectedTheme = value),
              ),
              const Divider(height: 1),
              _ColorPicker(
                label: 'Accent Color',
                selectedColor: _accentColor,
                colors: _themeColors,
                onChanged: (color) => setState(() => _accentColor = color),
              ),
              const Divider(height: 1),
              _BubbleStyleSelector(
                value: _bubbleStyle,
                onChanged: (value) => setState(() => _bubbleStyle = value),
              ),
              const Divider(height: 1),
              _FontSizeSlider(
                value: _fontSize,
                onChanged: (value) => setState(() => _fontSize = value),
              ),
              const Divider(height: 1),
              _ToggleRow(
                label: 'Reduced Motion',
                subtitle: 'Minimize animations in chat',
                value: _reducedMotion,
                onChanged: (value) => setState(() => _reducedMotion = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Backup Section
          _SectionCard(
            title: 'Message Backup',
            icon: Icons.cloud_outlined,
            children: [
              _ToggleRow(
                label: 'Auto Backup',
                subtitle: 'Automatically backup chat messages',
                value: _autoBackup,
                onChanged: (value) => setState(() => _autoBackup = value),
              ),
              if (_autoBackup) ...[
                const Divider(height: 1),
                _BackupFrequencySelector(
                  value: _backupFrequency,
                  options: _backupFrequencies,
                  onChanged: (value) => setState(() => _backupFrequency = value),
                ),
                const Divider(height: 1),
                _ToggleRow(
                  label: 'Include Media',
                  subtitle: 'Backup images and files',
                  value: _includeMedia,
                  onChanged: (value) => setState(() => _includeMedia = value),
                ),
              ],
              const Divider(height: 1),
              _BackupActions(
                lastBackup: _lastBackup,
                onBackupNow: _backupNow,
                onRestore: _restoreBackup,
                onExport: _exportChat,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Media & Storage Section
          _SectionCard(
            title: 'Media & Storage',
            icon: Icons.photo_library_outlined,
            children: [
              _StorageInfo(channelId: widget.channelId),
              const Divider(height: 1),
              _ActionRow(
                label: 'Clear Media',
                subtitle: 'Remove cached images and files',
                icon: Icons.delete_outline,
                onTap: _clearMedia,
              ),
              const Divider(height: 1),
              _ActionRow(
                label: 'Download All Media',
                subtitle: 'Save all shared media to device',
                icon: Icons.download,
                onTap: _downloadAllMedia,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
  
  void _showChatInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat Information',
              style: context.textStyles.titleLarge?.semiBold,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoItem(label: 'Created', value: 'Jan 15, 2024'),
            _InfoItem(label: 'Messages', value: '1,234'),
            _InfoItem(label: 'Media Files', value: '56'),
            _InfoItem(label: 'Storage Used', value: '45.2 MB'),
            const SizedBox(height: AppSpacing.lg),
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
    
    if (confirmed == true) {
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
        title: const Text('Clear Media'),
        content: const Text(
          'This will remove all cached images and files from this chat. You can download them again if needed.',
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
    
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media cleared!')),
      );
    }
  }
  
  Future<void> _downloadAllMedia() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading all media...')),
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDM ? Icons.person : Icons.group,
              color: cs.primary,
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
                Text(
                  isDM ? 'Direct Message' : 'Group Chat',
                  style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title.toUpperCase(),
                  style: context.textStyles.labelSmall?.withColor(cs.primary),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

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

class _MuteRow extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  
  const _MuteRow({
    required this.value,
    required this.options,
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
                Text('Mute Notifications', style: context.textStyles.bodyMedium),
                Text(
                  value == 'Off' ? 'Notifications enabled' : 'Muted for $value',
                  style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            initialValue: value,
            onSelected: onChanged,
            child: Chip(
              label: Text(value),
              avatar: Icon(
                value == 'Off' ? Icons.notifications : Icons.notifications_off,
                size: 18,
              ),
            ),
            itemBuilder: (context) => options.map((o) => PopupMenuItem(
              value: o,
              child: Text(o),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SoundSelector extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  
  const _SoundSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Notification Sound', style: context.textStyles.bodyMedium),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: (v) => v != null ? onChanged(v) : null,
            items: options.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String> onChanged;
  
  const _ThemeSelector({
    required this.selectedTheme,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themes = ['default', 'minimal', 'gradient', 'classic'];
    
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
                onSelected: (_) => onChanged(theme),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String label;
  final Color selectedColor;
  final List<Color> colors;
  final ValueChanged<Color> onChanged;
  
  const _ColorPicker({
    required this.label,
    required this.selectedColor,
    required this.colors,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: colors.map((color) {
              final isSelected = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(color);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
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
  final ValueChanged<String> onChanged;
  
  const _BubbleStyleSelector({
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final styles = ['modern', 'rounded', 'classic', 'flat'];
    
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
                onSelected: (_) => onChanged(style),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  
  const _FontSizeSlider({
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Message Font Size', style: context.textStyles.bodyMedium),
              Text('${value.toInt()}px', style: context.textStyles.bodySmall),
            ],
          ),
          Slider(
            value: value,
            min: 12,
            max: 24,
            divisions: 6,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('A', style: TextStyle(fontSize: 12)),
              Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupFrequencySelector extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  
  const _BackupFrequencySelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Backup Frequency', style: context.textStyles.bodyMedium),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: (v) => v != null ? onChanged(v) : null,
            items: options.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _BackupActions extends StatelessWidget {
  final DateTime? lastBackup;
  final VoidCallback onBackupNow;
  final VoidCallback onRestore;
  final VoidCallback onExport;
  
  const _BackupActions({
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
            Text(
              'Last backup: ${_formatDate(lastBackup!)}',
              style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.md),
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

class _StorageInfo extends StatelessWidget {
  final String? channelId;
  
  const _StorageInfo({this.channelId});
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage Used', style: context.textStyles.bodyMedium),
              Text('45.2 MB', style: context.textStyles.bodyMedium?.semiBold),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.35,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StorageStat(label: 'Images', value: '32 MB', color: Colors.blue),
              _StorageStat(label: 'Videos', value: '10 MB', color: Colors.purple),
              _StorageStat(label: 'Files', value: '3.2 MB', color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StorageStat({
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: context.textStyles.labelSmall,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  
  const _ActionRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textStyles.bodyMedium),
                  Text(
                    subtitle,
                    style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoItem({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
          Text(value, style: context.textStyles.bodyMedium?.semiBold),
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
