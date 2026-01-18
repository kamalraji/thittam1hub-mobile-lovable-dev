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
}
