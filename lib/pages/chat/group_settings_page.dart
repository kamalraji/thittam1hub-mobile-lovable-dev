import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/chat_group.dart';
import '../../services/group_chat_service.dart';
import '../../services/group_icon_service.dart';
import '../../widgets/styled_text_field.dart';
import '../../widgets/styled_button.dart';
import '../../widgets/settings_components.dart';
import '../../widgets/role_badge.dart';
import '../../theme.dart';
import 'add_group_members_page.dart';

/// Enhanced Group Settings page with analytics, activity log, and visual polish
class GroupSettingsPage extends StatefulWidget {
  final String groupId;

  const GroupSettingsPage({super.key, required this.groupId});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage>
    with TickerProviderStateMixin {
  final _groupService = GroupChatService();
  final _iconService = GroupIconService();

  ChatGroup? _group;
  List<ChatGroupMember> _members = [];
  ChatGroupMember? _currentMembership;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingIcon = false;
  String _searchQuery = '';

  // Settings
  bool _isMuted = false;
  bool _pinConversation = false;
  bool _hideFromList = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerScale;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _headerScale = CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final group = await _groupService.getGroupById(widget.groupId);
      final members = await _groupService.getGroupMembers(widget.groupId);
      final membership = await _groupService.getCurrentMembership(widget.groupId);

      if (mounted) {
        setState(() {
          _group = group;
          _members = members;
          _currentMembership = membership;
          _isMuted = membership?.isMuted ?? false;
          _nameController.text = group.name;
          _descriptionController.text = group.description ?? '';
          _isLoading = false;
        });
        _fadeController.forward();
        _headerController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group: $e')),
        );
      }
    }
  }

  bool get _canEdit => _currentMembership?.role.canEditGroup ?? false;
  bool get _canManageMembers => _currentMembership?.role.canManageMembers ?? false;
  bool get _isOwner => _currentMembership?.role == GroupMemberRole.owner;

  List<ChatGroupMember> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((m) => 
      m.displayName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _saveChanges() async {
    if (_group == null) return;

    try {
      await _groupService.updateGroup(
        widget.groupId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() => _isEditing = false);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _changeGroupIcon() async {
    if (!_canEdit) return;

    setState(() => _isUploadingIcon = true);

    try {
      final url = await _iconService.uploadGroupIcon(widget.groupId);
      if (url != null && mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group icon updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload icon: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingIcon = false);
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text(
          _isOwner
              ? 'As the owner, leaving will transfer ownership to another member or delete the group if you\'re the only member.'
              : 'Are you sure you want to leave this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.leaveGroup(widget.groupId);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.deleteGroup(widget.groupId);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showMemberOptions(ChatGroupMember member) {
    final isSelf = member.userId == _currentMembership?.userId;
    final canModify = _canManageMembers && !isSelf && 
        member.role != GroupMemberRole.owner;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          final cs = Theme.of(context).colorScheme;
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    _MemberAvatar(
                      name: member.displayName,
                      avatarUrl: member.userAvatar,
                      isOnline: member.isOnline ?? false,
                      size: 56,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: context.textStyles.titleMedium?.semiBold,
                          ),
                          const SizedBox(height: 4),
                          MessageRoleBadge(role: member.role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (_isOwner && canModify) ...[
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('Change Role'),
                        subtitle: Text('Current: ${member.role.displayName}'),
                        onTap: () {
                          Navigator.pop(context);
                          _showRolePicker(member);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: const Text('Transfer Ownership'),
                        subtitle: const Text('Make this member the owner'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _transferOwnership(member);
                        },
                      ),
                    ],
                    ListTile(
                      leading: const Icon(Icons.message),
                      title: const Text('Send Message'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to DM
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('View Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to profile
                      },
                    ),
                    if (canModify)
                      ListTile(
                        leading: Icon(Icons.remove_circle, color: AppColors.error),
                        title: Text(
                          'Remove from Group',
                          style: TextStyle(color: AppColors.error),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await _removeMember(member);
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRolePicker(ChatGroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final role in [
              GroupMemberRole.admin,
              GroupMemberRole.moderator,
              GroupMemberRole.member,
            ])
              RadioListTile<GroupMemberRole>(
                title: Text(role.displayName),
                subtitle: Text(_roleDescription(role)),
                value: role,
                groupValue: member.role,
                onChanged: (value) async {
                  Navigator.pop(context);
                  if (value != null && value != member.role) {
                    await _groupService.updateMemberRole(
                      widget.groupId,
                      member.userId,
                      value,
                    );
                    _loadData();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _roleDescription(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.owner:
        return 'Full control over the group';
      case GroupMemberRole.admin:
        return 'Can manage members and settings';
      case GroupMemberRole.moderator:
        return 'Can manage messages';
      case GroupMemberRole.member:
        return 'Can send messages';
    }
  }

  Future<void> _transferOwnership(ChatGroupMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Ownership'),
        content: Text(
          'Are you sure you want to transfer ownership to ${member.displayName}? You will become an admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.transferOwnership(widget.groupId, member.userId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ownership transferred')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(ChatGroupMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.displayName} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.removeMember(widget.groupId, member.userId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: cs.error),
              const SizedBox(height: AppSpacing.md),
              Text('Group not found', style: context.textStyles.titleMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        actions: [
          if (_canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
          ],
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Group Header
            SliverToBoxAdapter(
              child: ScaleTransition(
                scale: _headerScale,
                child: _buildGroupHeader(cs),
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildQuickStats(cs),
              ),
            ),

            // Settings Sections
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Notification Settings
                  _buildNotificationSection(),
                  const SizedBox(height: AppSpacing.md),

                  // Members Section
                  _buildMembersSection(cs),
                  const SizedBox(height: AppSpacing.md),

                  // Media & Links Section
                  _buildMediaSection(),
                  const SizedBox(height: AppSpacing.md),

                  // Privacy Section
                  _buildPrivacySection(),
                  const SizedBox(height: AppSpacing.md),

                  // Danger Zone
                  _buildDangerZone(),
                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.1),
            cs.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Group Icon
          GestureDetector(
            onTap: _canEdit ? _changeGroupIcon : null,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                    image: _group!.iconUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_group!.iconUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploadingIcon
                      ? const Center(child: CircularProgressIndicator())
                      : _group!.iconUrl == null
                          ? Center(
                              child: Text(
                                _group!.name[0].toUpperCase(),
                                style: context.textStyles.displaySmall?.bold
                                    .withColor(cs.primary),
                              ),
                            )
                          : null,
                ),
                if (_canEdit && !_isUploadingIcon)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Group Name & Description
          if (_isEditing) ...[
            StyledTextField(
              controller: _nameController,
              label: 'Group Name',
            ),
            const SizedBox(height: AppSpacing.md),
            StyledTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              maxLines: 2,
            ),
          ] else ...[
            Text(
              _group!.name,
              style: context.textStyles.headlineMedium?.bold,
              textAlign: TextAlign.center,
            ),
            if (_group!.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _group!.description!,
                style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          
          // Member count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${_group!.memberCount} members',
                  style: context.textStyles.labelMedium?.withColor(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.message,
                label: 'Messages',
                value: '1.2K',
                color: AppColors.violet500,
              ),
            ),
            Container(width: 1, height: 40, color: cs.outline.withOpacity(0.2)),
            Expanded(
              child: _StatItem(
                icon: Icons.photo_library,
                label: 'Media',
                value: '56',
                color: AppColors.pink500,
              ),
            ),
            Container(width: 1, height: 40, color: cs.outline.withOpacity(0.2)),
            Expanded(
              child: _StatItem(
                icon: Icons.link,
                label: 'Links',
                value: '23',
                color: AppColors.teal500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return SettingsSection(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      iconColor: AppColors.violet500,
      children: [
        SettingsToggle(
          label: 'Mute Notifications',
          subtitle: 'Stop receiving notifications from this group',
          icon: Icons.notifications_off_outlined,
          value: _isMuted,
          onChanged: (v) async {
            await _groupService.toggleMute(widget.groupId);
            setState(() => _isMuted = v);
          },
        ),
        const SettingsDivider(),
        SettingsToggle(
          label: 'Pin Conversation',
          subtitle: 'Keep this chat at the top',
          icon: Icons.push_pin_outlined,
          value: _pinConversation,
          onChanged: (v) => setState(() => _pinConversation = v),
        ),
      ],
    );
  }

  Widget _buildMembersSection(ColorScheme cs) {
    return SettingsSection(
      title: 'Members (${_members.length})',
      icon: Icons.people_outline,
      iconColor: AppColors.emerald500,
      trailing: _canManageMembers
          ? TextButton.icon(
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddGroupMembersPage(groupId: widget.groupId),
                  ),
                );
                if (added == true) _loadData();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            )
          : null,
      children: [
        // Search members
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SettingsSearchBar(
            onChanged: (q) => setState(() => _searchQuery = q),
            hintText: 'Search members...',
          ),
        ),
        
        // Member list
        ..._filteredMembers.map((member) => _MemberTile(
          member: member,
          onTap: () => _showMemberOptions(member),
        )),
      ],
    );
  }

  Widget _buildMediaSection() {
    return SettingsSection(
      title: 'Media & Links',
      icon: Icons.photo_library_outlined,
      iconColor: AppColors.pink500,
      initiallyExpanded: false,
      children: [
        SettingsAction(
          label: 'View Media Gallery',
          subtitle: 'Photos and videos shared in this group',
          icon: Icons.collections,
          onTap: () {},
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'View Shared Links',
          subtitle: 'Links shared in this group',
          icon: Icons.link,
          onTap: () {},
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'View Shared Files',
          subtitle: 'Documents and files shared in this group',
          icon: Icons.folder_outlined,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return SettingsSection(
      title: 'Privacy',
      icon: Icons.lock_outline,
      iconColor: AppColors.teal500,
      initiallyExpanded: false,
      children: [
        SettingsToggle(
          label: 'Hide from Chat List',
          subtitle: 'Access this group only from search',
          icon: Icons.visibility_off_outlined,
          value: _hideFromList,
          onChanged: (v) => setState(() => _hideFromList = v),
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'Export Chat',
          subtitle: 'Download all messages as a file',
          icon: Icons.download,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting chat...')),
            );
          },
        ),
        const SettingsDivider(),
        SettingsAction(
          label: 'Clear Chat History',
          subtitle: 'Delete all messages for yourself',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear Chat History'),
                content: const Text('This will delete all messages for you. Other members will still see them.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return SettingsSection(
      title: 'Danger Zone',
      icon: Icons.warning_amber,
      iconColor: AppColors.error,
      initiallyExpanded: false,
      children: [
        SettingsAction(
          label: 'Leave Group',
          subtitle: 'You will no longer receive messages',
          icon: Icons.exit_to_app,
          isDestructive: true,
          onTap: _leaveGroup,
        ),
        if (_isOwner) ...[
          const SettingsDivider(),
          SettingsAction(
            label: 'Delete Group',
            subtitle: 'Permanently delete this group and all messages',
            icon: Icons.delete_forever,
            isDestructive: true,
            onTap: _deleteGroup,
          ),
        ],
      ],
    );
  }
}

// ============ Helper Widgets ============

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textStyles.titleMedium?.bold,
        ),
        Text(
          label,
          style: context.textStyles.labelSmall?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final double size;

  const _MemberAvatar({
    required this.name,
    this.avatarUrl,
    required this.isOnline,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            image: avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: avatarUrl == null
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ChatGroupMember member;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.onTap});

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
            _MemberAvatar(
              name: member.displayName,
              avatarUrl: member.userAvatar,
              isOnline: member.isOnline ?? false,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: context.textStyles.bodyMedium?.semiBold,
                  ),
                  const SizedBox(height: 2),
                  MessageRoleBadge(role: member.role, mini: true),
                ],
              ),
            ),
            if (member.role == GroupMemberRole.owner)
              Icon(Icons.star, color: AppColors.amber500, size: 20),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
