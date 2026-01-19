import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_group.dart';

/// Service for managing group chats
class GroupChatService {
  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ==================== Group Management ====================

  /// Create a new group
  Future<ChatGroup> createGroup({
    required String name,
    String? description,
    String? iconUrl,
    List<String> memberIds = const [],
    bool isPublic = false,
    int maxMembers = 100,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Create the group
    final groupData = await _supabase
        .from('chat_groups')
        .insert({
          'name': name,
          'description': description,
          'icon_url': iconUrl,
          'created_by': userId,
          'is_public': isPublic,
          'max_members': maxMembers,
        })
        .select()
        .single();

    final group = ChatGroup.fromJson(groupData);

    // Add creator as owner
    await _supabase.from('chat_group_members').insert({
      'group_id': group.id,
      'user_id': userId,
      'role': 'owner',
    });

    // Add initial members
    if (memberIds.isNotEmpty) {
      final memberInserts = memberIds
          .where((id) => id != userId)
          .map((id) => {
                'group_id': group.id,
                'user_id': id,
                'role': 'member',
                'invited_by': userId,
              })
          .toList();

      if (memberInserts.isNotEmpty) {
        await _supabase.from('chat_group_members').insert(memberInserts);
      }
    }

    return group;
  }

  /// Update group settings
  Future<ChatGroup> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? iconUrl,
    bool? isPublic,
    int? maxMembers,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (iconUrl != null) updates['icon_url'] = iconUrl;
    if (isPublic != null) updates['is_public'] = isPublic;
    if (maxMembers != null) updates['max_members'] = maxMembers;

    if (updates.isEmpty) {
      return await getGroupById(groupId);
    }

    final data = await _supabase
        .from('chat_groups')
        .update(updates)
        .eq('id', groupId)
        .select()
        .single();

    return ChatGroup.fromJson(data);
  }

  /// Delete a group (owner only)
  Future<void> deleteGroup(String groupId) async {
    await _supabase.from('chat_groups').delete().eq('id', groupId);
  }

  /// Get groups the current user belongs to
  Future<List<ChatGroup>> getMyGroups() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final memberData = await _supabase
        .from('chat_group_members')
        .select('group_id')
        .eq('user_id', userId);

    if (memberData.isEmpty) return [];

    final groupIds =
        (memberData as List).map((m) => m['group_id'] as String).toList();

    final groupsData = await _supabase
        .from('chat_groups')
        .select()
        .inFilter('id', groupIds)
        .order('updated_at', ascending: false);

    return (groupsData as List)
        .map((g) => ChatGroup.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  /// Get a single group by ID
  Future<ChatGroup> getGroupById(String groupId) async {
    final data = await _supabase
        .from('chat_groups')
        .select()
        .eq('id', groupId)
        .single();

    return ChatGroup.fromJson(data);
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Check if user is owner
    final membership = await _supabase
        .from('chat_group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .single();

    if (membership['role'] == 'owner') {
      // Check if there are other members
      final members = await _supabase
          .from('chat_group_members')
          .select('id, user_id, role')
          .eq('group_id', groupId)
          .neq('user_id', userId);

      if ((members as List).isEmpty) {
        // No other members, delete the group
        await deleteGroup(groupId);
        return;
      }

      // Transfer ownership to first admin, or first member
      final admins = members.where((m) => m['role'] == 'admin').toList();
      final newOwnerId = admins.isNotEmpty
          ? admins.first['user_id']
          : members.first['user_id'];

      await transferOwnership(groupId, newOwnerId);
    }

    // Remove self from group
    await _supabase
        .from('chat_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // ==================== Member Management ====================

  /// Add members to a group
  Future<void> addMembers(String groupId, List<String> userIds) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Get existing members to avoid duplicates
    final existing = await _supabase
        .from('chat_group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final existingIds =
        (existing as List).map((m) => m['user_id'] as String).toSet();

    final newMembers = userIds
        .where((id) => !existingIds.contains(id))
        .map((id) => {
              'group_id': groupId,
              'user_id': id,
              'role': 'member',
              'invited_by': userId,
            })
        .toList();

    if (newMembers.isNotEmpty) {
      await _supabase.from('chat_group_members').insert(newMembers);
    }
  }

  /// Remove a member from a group
  Future<void> removeMember(String groupId, String memberId) async {
    await _supabase
        .from('chat_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', memberId);
  }

  /// Update a member's role
  Future<void> updateMemberRole(
    String groupId,
    String memberId,
    GroupMemberRole role,
  ) async {
    await _supabase
        .from('chat_group_members')
        .update({'role': role.name})
        .eq('group_id', groupId)
        .eq('user_id', memberId);
  }

  /// Get all members of a group with their profile data
  Future<List<ChatGroupMember>> getGroupMembers(String groupId) async {
    final data = await _supabase
        .from('chat_group_members')
        .select('''
          *,
          impact_profiles!chat_group_members_user_id_fkey (
            full_name,
            avatar_url,
            is_online
          )
        ''')
        .eq('group_id', groupId)
        .order('role', ascending: true)
        .order('joined_at', ascending: true);

    return (data as List)
        .map((m) => ChatGroupMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Transfer group ownership to another member
  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Demote current owner to admin
    await _supabase
        .from('chat_group_members')
        .update({'role': 'admin'})
        .eq('group_id', groupId)
        .eq('user_id', userId);

    // Promote new owner
    await _supabase
        .from('chat_group_members')
        .update({'role': 'owner'})
        .eq('group_id', groupId)
        .eq('user_id', newOwnerId);
  }

  // ==================== Permission Checks ====================

  /// Check if current user can manage members in a group
  Future<bool> canManageMembers(String groupId) async {
    final role = await _getCurrentUserRole(groupId);
    return role?.canManageMembers ?? false;
  }

  /// Check if current user can edit group settings
  Future<bool> canEditGroup(String groupId) async {
    final role = await _getCurrentUserRole(groupId);
    return role?.canEditGroup ?? false;
  }

  /// Check if current user is admin or owner
  Future<bool> isGroupAdmin(String groupId) async {
    final role = await _getCurrentUserRole(groupId);
    return role == GroupMemberRole.admin || role == GroupMemberRole.owner;
  }

  /// Get current user's role in a group
  Future<GroupMemberRole?> _getCurrentUserRole(String groupId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('chat_group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .single();

      return GroupMemberRole.fromString(data['role'] as String);
    } catch (e) {
      return null;
    }
  }

  /// Get current user's membership in a group
  Future<ChatGroupMember?> getCurrentMembership(String groupId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('chat_group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .single();

      return ChatGroupMember.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ==================== Mute Settings ====================

  /// Toggle mute for a group
  Future<void> toggleMute(String groupId, {DateTime? mutedUntil}) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final current = await getCurrentMembership(groupId);
    if (current == null) throw Exception('Not a member');

    await _supabase
        .from('chat_group_members')
        .update({
          'is_muted': !current.isMuted,
          'muted_until': mutedUntil?.toIso8601String(),
        })
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  /// Update last read timestamp
  Future<void> markAsRead(String groupId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _supabase
        .from('chat_group_members')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // ==================== Real-time Subscriptions ====================

  /// Stream group membership changes
  Stream<List<ChatGroupMember>> streamGroupMembers(String groupId) {
    return _supabase
        .from('chat_group_members')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((data) => data
            .map((m) => ChatGroupMember.fromJson(m as Map<String, dynamic>))
            .toList());
  }

  /// Stream user's groups
  Stream<List<ChatGroup>> streamMyGroups() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('chat_group_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((memberData) async {
          if (memberData.isEmpty) return <ChatGroup>[];

          final groupIds = memberData.map((m) => m['group_id'] as String).toList();

          final groupsData = await _supabase
              .from('chat_groups')
              .select()
              .inFilter('id', groupIds)
              .order('updated_at', ascending: false);

          return (groupsData as List)
              .map((g) => ChatGroup.fromJson(g as Map<String, dynamic>))
              .toList();
        });
  }
}
