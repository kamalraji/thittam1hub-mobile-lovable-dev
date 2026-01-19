import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

class ChatService {
  static const String channelsTable = 'workspace_channels';
  static const String messagesTable = 'messages';
  static const String profilesTable = 'user_profiles';

  static SupabaseClient get _client => SupabaseConfig.client;

  // Fetch channels for current user (fallback to public channels if membership table is absent)
  static Future<List<WorkspaceChannel>> getMyChannels({String? workspaceId}) async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return [];

      // Attempt to fetch channels where current user is in members array
      dynamic query = _client.from(channelsTable).select();
      if (workspaceId != null) {
        query = query.eq('workspace_id', workspaceId);
      }
      query = query.order('name');

      final List<dynamic> rows = await query;
      final all = rows.map((e) => WorkspaceChannel.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      // If members array exists, filter on client
      final filtered = all.where((c) {
        try {
          if (c.members.isEmpty) return !c.isPrivate; // show public channels by default
          return c.members.contains(uid);
        } catch (_) {
          return !c.isPrivate;
        }
      }).toList();
      return filtered;
    } catch (e) {
      debugPrint('ChatService.getMyChannels error: $e');
      return [];
    }
  }

  // Batch fetch last message for channels
  static Future<Map<String, Message?>> getLastMessages(List<String> channelIds) async {
    final Map<String, Message?> result = {for (final id in channelIds) id: null};
    if (channelIds.isEmpty) return result;
    try {
      final rows = await _client
          .from(messagesTable)
          .select()
          .inFilter('channel_id', channelIds)
          .order('sent_at', ascending: false)
          .limit(1000);

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final msg = Message.fromJson(map);
        // First one encountered per channel is the latest due to ordering
        result.putIfAbsent(msg.channelId, () => msg);
        if (result[msg.channelId] == null) result[msg.channelId] = msg;
      }
    } catch (e) {
      debugPrint('ChatService.getLastMessages error: $e');
    }
    return result;
  }

  // ==========================
  // DIRECT MESSAGES (DM)
  // ==========================

  /// Deterministic DM channel id for two users
  static String dmChannelIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm:${ids[0]}:${ids[1]}';
  }

  /// Fetch recent DM threads for current user, derived from messages table
  static Future<List<DMThread>> getMyDMThreads({int limit = 200}) async {
    final me = SupabaseConfig.auth.currentUser?.id;
    if (me == null) return [];
    try {
      final rows = await _client
          .from(messagesTable)
          .select('channel_id, sender_id, sender_name, sender_avatar, content, sent_at')
          .ilike('channel_id', 'dm:%')
          .ilike('channel_id', '%$me%')
          .order('sent_at', ascending: false)
          .limit(limit);

      // Keep the latest per channel
      final Map<String, Message> latest = {};
      for (final r in rows) {
        final map = Map<String, dynamic>.from(r as Map);
        final msg = Message.fromJson(map);
        latest.putIfAbsent(msg.channelId, () => msg);
      }

      // Collect partner ids
      final Map<String, String> partnerByChannel = {};
      for (final chId in latest.keys) {
        // channel_id format: dm:<id1>:<id2>
        final parts = chId.split(':');
        if (parts.length == 3) {
          final id1 = parts[1];
          final id2 = parts[2];
          partnerByChannel[chId] = id1 == me ? id2 : id1;
        }
      }
      final partnerIds = partnerByChannel.values.toSet().toList();

      // Batch fetch partner profiles
      Map<String, Map<String, dynamic>> profileMap = {};
      if (partnerIds.isNotEmpty) {
        final profs = await _client
            .from(profilesTable)
            .select('id, full_name, avatar_url, email')
            .inFilter('id', partnerIds);
        for (final p in profs) {
          final m = Map<String, dynamic>.from(p as Map);
          profileMap[m['id'] as String] = m;
        }
      }

      // Build thread list
      final threads = <DMThread>[];
      for (final entry in latest.entries) {
        final chId = entry.key;
        final msg = entry.value;
        final partnerId = partnerByChannel[chId];
        if (partnerId == null) continue;
        final prof = profileMap[partnerId];
        final name = (prof?['full_name'] as String?)?.trim().isNotEmpty == true
            ? prof!['full_name'] as String
            : (prof?['email'] as String? ?? 'User');
        final avatar = prof?['avatar_url'] as String?;
        threads.add(DMThread(
          channelId: chId,
          partnerUserId: partnerId,
          partnerName: name,
          partnerAvatar: avatar,
          lastMessage: msg,
          updatedAt: msg.sentAt,
        ));
      }
      threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return threads;
    } catch (e) {
      debugPrint('ChatService.getMyDMThreads error: $e');
      return [];
    }
  }

  /// Search participants to start a DM
  static Future<List<UserProfile>> searchParticipants(String query, {int limit = 50}) async {
    final me = SupabaseConfig.auth.currentUser?.id;
    try {
      final rows = await _client
          .from(profilesTable)
          .select('id, email, full_name, avatar_url, bio, organization, phone, website, linkedin_url, twitter_url, github_url, qr_code, portfolio_is_public, portfolio_layout, portfolio_accent_color, portfolio_sections, created_at, updated_at')
          .order('full_name')
          .limit(200);
      final users = rows.map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final trimmed = query.trim().toLowerCase();
      final filtered = trimmed.isEmpty
          ? users
          : users.where((u) {
              final name = (u.fullName ?? '').toLowerCase();
              final email = (u.email).toLowerCase();
              return name.contains(trimmed) || email.contains(trimmed);
            }).toList();
      return filtered.where((u) => u.id != me).take(limit).toList();
    } catch (e) {
      debugPrint('ChatService.searchParticipants error: $e');
      return [];
    }
  }

  // Stream messages for a channel
  static Stream<List<Message>> streamMessages(String channelId) {
    try {
      return _client
          .from(messagesTable)
          .stream(primaryKey: ['id'])
          .eq('channel_id', channelId)
          .order('sent_at')
          .map((rows) => rows
              .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
              .toList());
    } catch (e) {
      debugPrint('ChatService.streamMessages error: $e');
      return const Stream.empty();
    }
  }

  // Send a message
  static Future<Message?> sendMessage({
    required String channelId,
    required String content,
    List<MessageAttachment> attachments = const [],
  }) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) return null;

      // Try to get profile for sender name/avatar
      String senderName = user.email?.split('@').first ?? 'You';
      String? senderAvatar;
      try {
        final profile = await _client
            .from('user_profiles')
            .select('full_name, avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          senderName = (profile['full_name'] as String?)?.trim().isNotEmpty == true
              ? profile['full_name'] as String
              : senderName;
          senderAvatar = profile['avatar_url'] as String?;
        }
      } catch (e) {
        debugPrint('ChatService.sendMessage profile lookup error: $e');
      }

      final data = {
        'channel_id': channelId,
        'sender_id': user.id,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'sent_at': DateTime.now().toIso8601String(),
      };
      final inserted = await _client.from(messagesTable).insert(data).select().maybeSingle();
      return inserted != null ? Message.fromJson(Map<String, dynamic>.from(inserted)) : null;
    } catch (e) {
      debugPrint('ChatService.sendMessage error: $e');
      return null;
    }
  }

  // Realtime typing indicator using broadcast channel
  static RealtimeChannel typingChannel(String channelId) {
    return _client.channel('typing:$channelId');
  }

  static Future<void> sendTyping(String channelId, {required String name, required String userId}) async {
    try {
      final ch = typingChannel(channelId);
      await ch.sendBroadcastMessage(event: 'typing', payload: {
        'userId': userId,
        'name': name,
        'ts': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('ChatService.sendTyping error: $e');
    }
  }

  // ==========================
  // MESSAGE REACTIONS
  // ==========================

  /// Add a reaction to a message
  static Future<void> addReaction(String messageId, String emoji) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });
      debugPrint('✅ Reaction added');
    } catch (e) {
      debugPrint('ChatService.addReaction error: $e');
    }
  }

  /// Remove a reaction from a message
  static Future<void> removeReaction(String messageId, String emoji) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
      debugPrint('❌ Reaction removed');
    } catch (e) {
      debugPrint('ChatService.removeReaction error: $e');
    }
  }

  /// Stream reactions for a channel's messages
  static Stream<List<Map<String, dynamic>>> streamReactions(String channelId) {
    try {
      return _client
          .from('message_reactions')
          .stream(primaryKey: ['id'])
          .map((rows) => rows.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {
      debugPrint('ChatService.streamReactions error: $e');
      return const Stream.empty();
    }
  }

  // ==========================
  // READ RECEIPTS
  // ==========================

  /// Mark a message as read
  static Future<void> markAsRead(String messageId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('message_read_receipts').upsert({
        'message_id': messageId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('ChatService.markAsRead error: $e');
    }
  }

  /// Get read receipts for messages
  static Future<Map<String, List<String>>> getReadReceipts(List<String> messageIds) async {
    final Map<String, List<String>> result = {};
    if (messageIds.isEmpty) return result;
    
    try {
      final rows = await _client
          .from('message_read_receipts')
          .select('message_id, user_id')
          .inFilter('message_id', messageIds);

      for (final row in rows) {
        final msgId = row['message_id'] as String;
        final userId = row['user_id'] as String;
        result.putIfAbsent(msgId, () => []).add(userId);
      }
    } catch (e) {
      debugPrint('ChatService.getReadReceipts error: $e');
    }
    return result;
  }

  // ==========================
  // UNREAD COUNTS
  // ==========================

  /// Get unread count for a single channel
  static Future<int> getUnreadCount(String channelId) async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      // Get last read timestamp for this user in this channel
      final membership = await _client
          .from('channel_members')
          .select('last_read_at')
          .eq('channel_id', channelId)
          .eq('user_id', userId)
          .maybeSingle();

      final lastReadAt = membership?['last_read_at'] as String?;
      
      // Count messages after last read
      var query = _client
          .from(messagesTable)
          .select()
          .eq('channel_id', channelId)
          .neq('sender_id', userId);
      
      if (lastReadAt != null) {
        query = query.gt('sent_at', lastReadAt);
      }
      
      final rows = await query;
      return (rows as List).length;
    } catch (e) {
      debugPrint('ChatService.getUnreadCount error: $e');
      return 0;
    }
  }

  /// Get unread counts for multiple channels
  static Future<Map<String, int>> getUnreadCounts(List<String> channelIds) async {
    final Map<String, int> result = {for (final id in channelIds) id: 0};
    if (channelIds.isEmpty) return result;

    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return result;

    try {
      // Batch fetch - simplified approach
      for (final channelId in channelIds) {
        result[channelId] = await getUnreadCount(channelId);
      }
    } catch (e) {
      debugPrint('ChatService.getUnreadCounts error: $e');
    }
    return result;
  }

  /// Update last read timestamp for a channel
  static Future<void> updateLastRead(String channelId) async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('channel_members').upsert({
        'channel_id': channelId,
        'user_id': userId,
        'last_read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('ChatService.updateLastRead error: $e');
    }
  }

  /// Get reactions grouped by message
  static Future<Map<String, List<Map<String, dynamic>>>> getReactionsForMessages(List<String> messageIds) async {
    final Map<String, List<Map<String, dynamic>>> result = {};
    if (messageIds.isEmpty) return result;

    try {
      final rows = await _client
          .from('message_reactions')
          .select('message_id, user_id, emoji')
          .inFilter('message_id', messageIds);

      for (final row in rows) {
        final msgId = row['message_id'] as String;
        result.putIfAbsent(msgId, () => []).add(Map<String, dynamic>.from(row as Map));
      }
    } catch (e) {
      debugPrint('ChatService.getReactionsForMessages error: $e');
    }
    return result;
  }

  // ==========================
  // ONLINE/OFFLINE PRESENCE
  // ==========================

  /// Set the current user's online status
  static Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from(profilesTable).update({
        'is_online': isOnline,
        'last_seen': isOnline ? null : DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      debugPrint('📶 Online status set to: $isOnline');
    } catch (e) {
      debugPrint('ChatService.setOnlineStatus error: $e');
    }
  }

  /// Update heartbeat (last_seen) for presence tracking
  static Future<void> updateHeartbeat() async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from(profilesTable).update({
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('ChatService.updateHeartbeat error: $e');
    }
  }

  /// Stream online status for a specific user
  static Stream<bool> streamUserOnlineStatus(String userId) {
    try {
      return _client
          .from(profilesTable)
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .map((rows) => rows.firstOrNull?['is_online'] == true);
    } catch (e) {
      debugPrint('ChatService.streamUserOnlineStatus error: $e');
      return const Stream.empty();
    }
  }

  /// Get last seen timestamp for a user
  static Future<DateTime?> getLastSeen(String userId) async {
    try {
      final row = await _client
          .from(profilesTable)
          .select('last_seen, is_online')
          .eq('id', userId)
          .maybeSingle();
      
      if (row == null) return null;
      if (row['is_online'] == true) return null; // User is online
      
      final lastSeen = row['last_seen'] as String?;
      return lastSeen != null ? DateTime.tryParse(lastSeen) : null;
    } catch (e) {
      debugPrint('ChatService.getLastSeen error: $e');
      return null;
    }
  }

  /// Get online status for a user (single check)
  static Future<bool> isUserOnline(String userId) async {
    try {
      final row = await _client
          .from(profilesTable)
          .select('is_online')
          .eq('id', userId)
          .maybeSingle();
      
      return row?['is_online'] == true;
    } catch (e) {
      debugPrint('ChatService.isUserOnline error: $e');
      return false;
    }
  }

  // ==========================
  // MESSAGE MANAGEMENT
  // ==========================

  /// Delete a message (soft delete)
  static Future<bool> deleteMessage(String messageId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from(messagesTable).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'is_deleted': true,
        'content': '', // Clear content for privacy
      }).eq('id', messageId).eq('sender_id', userId);
      
      debugPrint('🗑️ Message deleted');
      return true;
    } catch (e) {
      debugPrint('ChatService.deleteMessage error: $e');
      return false;
    }
  }

  /// Edit a message
  static Future<Message?> editMessage(String messageId, String newContent) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return null;

      final updated = await _client.from(messagesTable).update({
        'content': newContent,
        'edited_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId).eq('sender_id', userId).select().maybeSingle();

      if (updated != null) {
        debugPrint('✏️ Message edited');
        return Message.fromJson(Map<String, dynamic>.from(updated));
      }
      return null;
    } catch (e) {
      debugPrint('ChatService.editMessage error: $e');
      return null;
    }
  }

  /// Send an image message
  static Future<Message?> sendImageMessage({
    required String channelId,
    required String imagePath,
    String? caption,
  }) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return null;

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final storagePath = 'chat-images/$channelId/$fileName';

      // Note: Actual file upload would require dart:io File
      // This is the structure for the upload
      // final imageFile = File(imagePath);
      // await _client.storage.from('media-assets').upload(storagePath, imageFile);
      
      final imageUrl = _client.storage.from('media-assets').getPublicUrl(storagePath);

      // Send message with image attachment
      return sendMessage(
        channelId: channelId,
        content: caption ?? '',
        attachments: [
          MessageAttachment(
            filename: fileName,
            url: imageUrl,
            size: 0, // Would be calculated from actual file
          ),
        ],
      );
    } catch (e) {
      debugPrint('ChatService.sendImageMessage error: $e');
      return null;
    }
  }

  // ==========================
  // USER BLOCKING
  // ==========================

  /// Block a user
  static Future<void> blockUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('blocked_users').upsert({
        'user_id': userId,
        'blocked_user_id': targetUserId,
        'blocked_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('🚫 User blocked: $targetUserId');
    } catch (e) {
      debugPrint('ChatService.blockUser error: $e');
    }
  }

  /// Unblock a user
  static Future<void> unblockUser(String targetUserId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('blocked_users')
          .delete()
          .eq('user_id', userId)
          .eq('blocked_user_id', targetUserId);
      
      debugPrint('✅ User unblocked: $targetUserId');
    } catch (e) {
      debugPrint('ChatService.unblockUser error: $e');
    }
  }

  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String targetUserId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return false;

      final row = await _client
          .from('blocked_users')
          .select()
          .eq('user_id', userId)
          .eq('blocked_user_id', targetUserId)
          .maybeSingle();
      
      return row != null;
    } catch (e) {
      debugPrint('ChatService.isUserBlocked error: $e');
      return false;
    }
  }

  /// Get list of blocked user IDs
  static Future<List<String>> getBlockedUserIds() async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return [];

      final rows = await _client
          .from('blocked_users')
          .select('blocked_user_id')
          .eq('user_id', userId);

      return rows.map((r) => r['blocked_user_id'] as String).toList();
    } catch (e) {
      debugPrint('ChatService.getBlockedUserIds error: $e');
      return [];
    }
  }

  // ==========================
  // CONVERSATION MUTING
  // ==========================

  /// Mute a conversation
  static Future<void> muteConversation(String channelId, {Duration? duration}) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      final mutedUntil = duration != null
          ? DateTime.now().add(duration).toIso8601String()
          : null; // null = muted forever

      await _client.from('channel_members').upsert({
        'channel_id': channelId,
        'user_id': userId,
        'muted_until': mutedUntil,
        'is_muted': true,
      });
      
      debugPrint('🔇 Conversation muted: $channelId');
    } catch (e) {
      debugPrint('ChatService.muteConversation error: $e');
    }
  }

  /// Unmute a conversation
  static Future<void> unmuteConversation(String channelId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('channel_members').update({
        'is_muted': false,
        'muted_until': null,
      }).eq('channel_id', channelId).eq('user_id', userId);
      
      debugPrint('🔔 Conversation unmuted: $channelId');
    } catch (e) {
      debugPrint('ChatService.unmuteConversation error: $e');
    }
  }

  /// Check if a conversation is muted
  static Future<bool> isConversationMuted(String channelId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return false;

      final row = await _client
          .from('channel_members')
          .select('is_muted, muted_until')
          .eq('channel_id', channelId)
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return false;
      if (row['is_muted'] != true) return false;

      // Check if mute has expired
      final mutedUntil = row['muted_until'] as String?;
      if (mutedUntil != null) {
        final expiresAt = DateTime.tryParse(mutedUntil);
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          // Mute expired, unmute automatically
          await unmuteConversation(channelId);
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('ChatService.isConversationMuted error: $e');
      return false;
    }
  }

  /// Get mute status for multiple channels
  static Future<Map<String, bool>> getMuteStatuses(List<String> channelIds) async {
    final Map<String, bool> result = {for (final id in channelIds) id: false};
    if (channelIds.isEmpty) return result;

    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return result;

      final rows = await _client
          .from('channel_members')
          .select('channel_id, is_muted, muted_until')
          .eq('user_id', userId)
          .inFilter('channel_id', channelIds);

      for (final row in rows) {
        final chId = row['channel_id'] as String;
        final isMuted = row['is_muted'] == true;
        final mutedUntil = row['muted_until'] as String?;

        if (isMuted) {
          if (mutedUntil != null) {
            final expiresAt = DateTime.tryParse(mutedUntil);
            result[chId] = expiresAt == null || expiresAt.isAfter(DateTime.now());
          } else {
            result[chId] = true;
          }
        }
      }
    } catch (e) {
      debugPrint('ChatService.getMuteStatuses error: $e');
    }
    return result;
  }

  // ==========================
  // SEARCH & UTILITIES
  // ==========================

  /// Search messages in a channel
  static Future<List<Message>> searchMessages(String channelId, String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final rows = await _client
          .from(messagesTable)
          .select()
          .eq('channel_id', channelId)
          .ilike('content', '%${query.trim()}%')
          .order('sent_at', ascending: false)
          .limit(50);

      return rows
          .map((r) => Message.fromJson(Map<String, dynamic>.from(r as Map)))
          .where((m) => !m.isDeleted)
          .toList();
    } catch (e) {
      debugPrint('ChatService.searchMessages error: $e');
      return [];
    }
  }

  /// Get message by ID
  static Future<Message?> getMessageById(String messageId) async {
    try {
      final row = await _client
          .from(messagesTable)
          .select()
          .eq('id', messageId)
          .maybeSingle();

      if (row == null) return null;
      return Message.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('ChatService.getMessageById error: $e');
      return null;
    }
  }

  /// Forward a message to another channel
  static Future<Message?> forwardMessage(String messageId, String toChannelId) async {
    try {
      final original = await getMessageById(messageId);
      if (original == null || original.isDeleted) return null;

      return sendMessage(
        channelId: toChannelId,
        content: original.content,
        attachments: original.attachments,
      );
    } catch (e) {
      debugPrint('ChatService.forwardMessage error: $e');
      return null;
    }
  }

  /// Clear chat history for a channel (local/soft clear)
  static Future<void> clearChatHistory(String channelId) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return;

      // Update last_read to now, effectively hiding old messages
      await _client.from('channel_members').upsert({
        'channel_id': channelId,
        'user_id': userId,
        'cleared_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('🧹 Chat history cleared for: $channelId');
    } catch (e) {
      debugPrint('ChatService.clearChatHistory error: $e');
    }
  }
}
