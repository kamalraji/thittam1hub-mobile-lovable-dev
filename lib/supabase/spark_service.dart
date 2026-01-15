import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

enum SparkPostType { IDEA, SEEKING, OFFERING, QUESTION, ANNOUNCEMENT }

class SparkPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final SparkPostType type;
  final String title;
  final String content;
  final List<String> tags;
  final int sparkCount;
  final int commentCount;
  final DateTime createdAt;

  const SparkPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.type,
    required this.title,
    required this.content,
    required this.tags,
    required this.sparkCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory SparkPost.fromMap(Map<String, dynamic> map) {
    return SparkPost(
      id: map['id'],
      authorId: map['author_id'],
      authorName: map['author_name'] ?? 'Anonymous',
      authorAvatar: map['author_avatar'],
      type: SparkPostType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SparkPostType.IDEA,
      ),
      title: map['title'],
      content: map['content'],
      tags: List<String>.from(map['tags'] ?? []),
      sparkCount: map['spark_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'type': type.name,
      'title': title,
      'content': content,
      'tags': tags,
      'spark_count': sparkCount,
      'comment_count': commentCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SparkService {
  final _supabase = SupabaseConfig.client;

  /// Get all spark posts, optionally filtered by type
  Future<List<SparkPost>> getSparkPosts({SparkPostType? type}) async {
    try {
      final response = type != null
          ? await _supabase.from('spark_posts').select('*').eq('type', type.name).order('created_at', ascending: false)
          : await _supabase.from('spark_posts').select('*').order('created_at', ascending: false);

      return (response as List).map((data) => SparkPost.fromMap(data as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching spark posts: $e');
      return [];
    }
  }

  /// Create a new spark post
  Future<void> createSparkPost({
    required SparkPostType type,
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Get user profile for name and avatar
      final userProfileResponse = await _supabase.from('user_profiles').select('full_name, avatar_url').eq('user_id', userId);
      final userProfile = (userProfileResponse as List).isNotEmpty ? userProfileResponse.first : null;

      await _supabase.from('spark_posts').insert({
        'author_id': userId,
        'author_name': userProfile?['full_name'] ?? 'Anonymous',
        'author_avatar': userProfile?['avatar_url'],
        'type': type.name,
        'title': title,
        'content': content,
        'tags': tags,
      });
      debugPrint('✅ Spark post created');
    } catch (e) {
      debugPrint('❌ Error creating spark post: $e');
      rethrow;
    }
  }

  /// Add a spark (like) to a post
  Future<void> sparkPost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('spark_reactions').insert({
        'post_id': postId,
        'user_id': userId,
        'type': 'SPARK',
      });

      // Increment spark count
      await _supabase.rpc('increment_spark_count', params: {'post_id': postId});
      debugPrint('⚡ Sparked post');
    } catch (e) {
      debugPrint('❌ Error sparking post: $e');
      rethrow;
    }
  }

  /// Idempotent spark: only creates a spark if not already reacted by user
  /// Returns true if a new spark was created, false if already existed
  Future<bool> toggleSparkOnce(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final existing = await _supabase
          .from('spark_reactions')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .eq('type', 'SPARK')
          .maybeSingle();

      if (existing != null) {
        debugPrint('ℹ️ Already sparked this post');
        return false;
      }

      await sparkPost(postId);
      return true;
    } catch (e) {
      debugPrint('❌ Error toggling spark: $e');
      rethrow;
    }
  }

  /// Get trending posts (most sparks in last 24h)
  Future<List<SparkPost>> getTrendingPosts() async {
    try {
      final response = await _supabase
          .from('spark_posts')
          .select('*')
          .gte('created_at', DateTime.now().subtract(Duration(days: 7)).toIso8601String())
          .order('spark_count', ascending: false)
          .limit(10);

      return (response as List).map((data) => SparkPost.fromMap(data as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching trending posts: $e');
      return [];
    }
  }
}
