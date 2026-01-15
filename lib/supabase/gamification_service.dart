import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

@immutable
class BadgeItem {
  final String id;
  final String name;
  final String description;
  final String icon; // material icon name or emoji
  final String category; // NETWORKING, COMMUNITY, CONTRIBUTION, SPECIAL
  final int pointsRequired;
  final String rarity; // COMMON, RARE, EPIC, LEGENDARY

  const BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.pointsRequired,
    required this.rarity,
  });

  factory BadgeItem.fromMap(Map<String, dynamic> map) => BadgeItem(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? 'Badge',
        description: (map['description'] as String?) ?? '',
        icon: (map['icon'] as String?) ?? '🏅',
        category: (map['category'] as String?) ?? 'SPECIAL',
        pointsRequired: (map['points_required'] as int?) ?? 0,
        rarity: (map['rarity'] as String?) ?? 'COMMON',
      );
}

@immutable
class LeaderboardEntry {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int score;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.score,
    required this.rank,
  });
}

@immutable
class VibeGameItem {
  final String id;
  final String eventId;
  final String name;
  final String type; // QUICK_MATCH | TRIVIA | ICEBREAKER | POLL
  final String question;
  final List<String> options;
  final int? correctAnswerIndex; // only for TRIVIA
  final DateTime expiresAt;
  final int participantCount;

  const VibeGameItem({
    required this.id,
    required this.eventId,
    required this.name,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.expiresAt,
    required this.participantCount,
  });

  factory VibeGameItem.fromMap(Map<String, dynamic> map) => VibeGameItem(
        id: map['id'] as String,
        eventId: map['event_id'] as String? ?? 'global',
        name: (map['name'] as String?) ?? 'Vibe',
        type: (map['type'] as String?) ?? 'QUICK_MATCH',
        question: (map['question'] as String?) ?? '',
        options: List<String>.from(map['options'] ?? const []),
        correctAnswerIndex: map['correct_answer'] as int?,
        expiresAt: DateTime.tryParse(map['expires_at'] ?? '') ?? DateTime.now().add(const Duration(minutes: 5)),
        participantCount: (map['participant_count'] as int?) ?? 0,
      );
}

class GamificationService {
  final _supabase = SupabaseConfig.client;

  // ---------------- Badges ----------------
  Future<List<BadgeItem>> getAllBadges() async {
    try {
      final rows = await _supabase.from('badges').select('*');
      return (rows as List).map((e) => BadgeItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching badges, falling back to defaults: $e');
      // Fallback seed badges if table not present
      return const [
        BadgeItem(
          id: 'networker_1',
          name: 'Friendly Connector',
          description: 'Connect with 5 participants',
          icon: '🤝',
          category: 'NETWORKING',
          pointsRequired: 0,
          rarity: 'COMMON',
        ),
        BadgeItem(
          id: 'spark_1',
          name: 'Spark Starter',
          description: 'Create your first Spark post',
          icon: '⚡',
          category: 'CONTRIBUTION',
          pointsRequired: 0,
          rarity: 'COMMON',
        ),
        BadgeItem(
          id: 'quiz_whiz',
          name: 'Quiz Whiz',
          description: 'Answer a trivia correctly',
          icon: '🧠',
          category: 'SPECIAL',
          pointsRequired: 0,
          rarity: 'RARE',
        ),
      ];
    }
  }

  Future<List<String>> getMyBadgeIds() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return [];
      final row = await _supabase.from('impact_profiles').select('badges').eq('user_id', uid).maybeSingle();
      if (row == null) return [];
      return List<String>.from((row['badges'] as List?) ?? const []);
    } catch (e) {
      debugPrint('Error fetching my badges: $e');
      return [];
    }
  }

  Future<void> awardBadgeIfMissing(String badgeId) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final row = await _supabase.from('impact_profiles').select('id, badges').eq('user_id', uid).maybeSingle();
      if (row == null) return;
      final profileId = row['id'] as String;
      final current = List<String>.from((row['badges'] as List?) ?? const []);
      if (current.contains(badgeId)) return;
      current.add(badgeId);
      await _supabase.from('impact_profiles').update({'badges': current}).eq('id', profileId);
      debugPrint('🏅 Awarded badge $badgeId');
    } catch (e) {
      debugPrint('Error awarding badge: $e');
    }
  }

  // ---------------- Leaderboard ----------------
  Future<List<LeaderboardEntry>> getTopLeaderboard({int limit = 20}) async {
    try {
      final rows = await _supabase
          .from('impact_profiles')
          .select('user_id, full_name, avatar_url, impact_score')
          .order('impact_score', ascending: false)
          .limit(limit);
      int rank = 1;
      return (rows as List)
          .map((e) => LeaderboardEntry(
                userId: e['user_id'] as String,
                name: (e['full_name'] as String?) ?? 'User',
                avatarUrl: e['avatar_url'] as String?,
                score: (e['impact_score'] as int?) ?? 0,
                rank: rank++,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  // ---------------- Vibe Games & Trivia ----------------
  Future<VibeGameItem?> getActiveQuickMatch({String? eventId}) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final base = _supabase.from('vibe_games').select('*').eq('type', 'QUICK_MATCH').gte('expires_at', nowIso);
      final filtered = eventId != null ? base.eq('event_id', eventId) : base;
      final rows = await filtered.order('created_at', ascending: false).limit(1);
      if ((rows as List).isEmpty) return null;
      return VibeGameItem.fromMap(rows.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching active quick match: $e');
      // Fallback demo
      return VibeGameItem(
        id: 'demo_quick',
        eventId: 'global',
        name: 'Quick Match',
        type: 'QUICK_MATCH',
        question: "What's your ideal weekend?",
        options: const ['🏔️ Adventure outdoors', '🎮 Gaming marathon', '📚 Cozy reading', '🎉 Party with friends'],
        correctAnswerIndex: null,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        participantCount: 120,
      );
    }
  }

  Future<void> submitQuickMatch({required String gameId, required int optionIndex}) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');
      // Upsert to keep one response per user per game
      await _supabase.from('vibe_responses').upsert({
        'game_id': gameId,
        'user_id': uid,
        'response': optionIndex.toString(), // Required field in schema
        'option_index': optionIndex,
      }, onConflict: 'game_id,user_id');
    } catch (e) {
      debugPrint('Error submitting quick match: $e');
      rethrow;
    }
  }

  Future<VibeGameItem?> getActiveTrivia({String? eventId}) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final base = _supabase.from('vibe_games').select('*').eq('type', 'TRIVIA').gte('expires_at', nowIso);
      final filtered = eventId != null ? base.eq('event_id', eventId) : base;
      final rows = await filtered.order('created_at', ascending: false).limit(1);
      if ((rows as List).isEmpty) return null;
      return VibeGameItem.fromMap(rows.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching active trivia: $e');
      // Fallback
      return VibeGameItem(
        id: 'demo_trivia',
        eventId: 'global',
        name: 'Trivia Challenge',
        type: 'TRIVIA',
        question: 'Which company created Flutter?',
        options: const ['Facebook', 'Google', 'Microsoft', 'Amazon'],
        correctAnswerIndex: 1,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        participantCount: 58,
      );
    }
  }

  Future<bool> submitTrivia({required VibeGameItem trivia, required int optionIndex}) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');
      await _supabase.from('trivia_responses').upsert({
        'game_id': trivia.id,
        'user_id': uid,
        'option_index': optionIndex,
        'is_correct': trivia.correctAnswerIndex != null && trivia.correctAnswerIndex == optionIndex,
      }, onConflict: 'game_id,user_id');
      return trivia.correctAnswerIndex != null && trivia.correctAnswerIndex == optionIndex;
    } catch (e) {
      debugPrint('Error submitting trivia: $e');
      rethrow;
    }
  }

  Future<void> addImpactPoints(int delta) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final row = await _supabase.from('impact_profiles').select('id, impact_score').eq('user_id', uid).maybeSingle();
      if (row == null) return;
      final id = row['id'] as String;
      final current = (row['impact_score'] as int?) ?? 0;
      await _supabase.from('impact_profiles').update({'impact_score': current + delta}).eq('id', id);
      debugPrint('➕ Added $delta impact points');
    } catch (e) {
      debugPrint('Error adding impact points: $e');
    }
  }
}
