import 'package:flutter/material.dart';
import '../../models/chat_group.dart';
import '../../services/group_chat_service.dart';
import '../../widgets/styled_text_field.dart';
import '../../widgets/styled_button.dart';
import '../../theme.dart';
import 'add_group_members_page.dart';

class GroupSettingsPage extends StatefulWidget {
  final String groupId;

  const GroupSettingsPage({super.key, required this.groupId});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final _groupService = GroupChatService();

  ChatGroup? _group;
  List<ChatGroupMember> _members = [];
  ChatGroupMember? _currentMembership;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final group = await _groupService.getGroupById(widget.groupId);
      final members = await _groupService.getGroupMembers(widget.groupId);
      final membership =
          await _groupService.getCurrentMembership(widget.groupId);

      if (mounted) {
        setState(() {
          _group = group;
          _members = members;
          _currentMembership = membership;
          _nameController.text = group.name;
          _descriptionController.text = group.description ?? '';
          _isLoading = false;
        });
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

  bool get _canEdit =>
      _currentMembership?.role.canEditGroup ?? false;

  bool get _canManageMembers =>
      _currentMembership?.role.canManageMembers ?? false;

  bool get _isOwner =>
      _currentMembership?.role == GroupMemberRole.owner;

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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: member.userAvatar != null
                    ? NetworkImage(member.userAvatar!)
                    : null,
                child: member.userAvatar == null
                    ? Text(member.displayName[0].toUpperCase())
                    : null,
              ),
              title: Text(member.displayName),
              subtitle: Text(member.role.displayName),
            ),
            const Divider(),
            if (_isOwner && canModify) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Change Role'),
                onTap: () {
                  Navigator.pop(context);
                  _showRolePicker(member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transfer Ownership'),
                onTap: () async {
                  Navigator.pop(context);
                  await _transferOwnership(member);
                },
              ),
            ],
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
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to DM
              },
            ),
          ],
        ),
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
          TextButton(
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: Text('Group not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        actions: [
          if (_canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: ListView(
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _group!.iconUrl != null
                      ? NetworkImage(_group!.iconUrl!)
                      : null,
                  child: _group!.iconUrl == null
                      ? Text(
                          _group!.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  StyledTextField(
                    controller: _nameController,
                    label: 'Group Name',
                  ),
                  const SizedBox(height: 12),
                  StyledTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 2,
                  ),
                ] else ...[
                  Text(
                    _group!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_group!.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _group!.description!,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                Text(
                  '${_group!.memberCount} members',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(),

          // Members Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_canManageMembers)
                  TextButton.icon(
                    onPressed: () async {
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddGroupMembersPage(groupId: widget.groupId),
                        ),
                      );
                      if (added == true) _loadData();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
          ),

          // Member List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: member.userAvatar != null
                          ? NetworkImage(member.userAvatar!)
                          : null,
                      child: member.userAvatar == null
                          ? Text(member.displayName[0].toUpperCase())
                          : null,
                    ),
                    if (member.isOnline == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(member.displayName),
                subtitle: Text(member.role.displayName),
                trailing: member.role == GroupMemberRole.owner
                    ? const Icon(Icons.star, color: Colors.amber)
                    : member.role == GroupMemberRole.admin
                        ? const Icon(Icons.admin_panel_settings,
                            color: Colors.blue)
                        : null,
                onTap: () => _showMemberOptions(member),
              );
            },
          ),

          const Divider(),
          const SizedBox(height: 16),

          // Mute Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              title: const Text('Mute Notifications'),
              subtitle: const Text('Stop receiving notifications'),
              value: _currentMembership?.isMuted ?? false,
              onChanged: (value) async {
                await _groupService.toggleMute(widget.groupId);
                _loadData();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Leave Group
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StyledButton(
              onPressed: _leaveGroup,
              label: 'Leave Group',
              icon: Icons.exit_to_app,
              variant: ButtonVariant.outline,
            ),
          ),

          // Delete Group (owner only)
          if (_isOwner) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StyledButton(
                onPressed: _deleteGroup,
                label: 'Delete Group',
                icon: Icons.delete_forever,
                variant: ButtonVariant.outline,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
