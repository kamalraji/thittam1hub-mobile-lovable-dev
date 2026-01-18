import 'package:flutter/material.dart';
import 'package:thittam1hub/supabase/spark_service.dart';

/// Centralized icon mapping utility for consistent icon usage across the app.
/// All icon definitions are consolidated here to ensure visual consistency.
class IconMappings {
  IconMappings._();

  // ============================================
  // SPARK POST TYPE ICONS
  // ============================================

  /// Get icon for a SparkPostType
  static IconData getSparkPostIcon(SparkPostType type) {
    return _sparkPostIcons[type] ?? Icons.article_outlined;
  }

  /// Get color for a SparkPostType
  static Color getSparkPostColor(SparkPostType type, ColorScheme cs) {
    switch (type) {
      case SparkPostType.IDEA:
        return Colors.amber;
      case SparkPostType.SEEKING:
        return Colors.blue;
      case SparkPostType.OFFERING:
        return Colors.green;
      case SparkPostType.QUESTION:
        return Colors.purple;
      case SparkPostType.ANNOUNCEMENT:
        return cs.primary;
    }
  }

  static const Map<SparkPostType, IconData> _sparkPostIcons = {
    SparkPostType.IDEA: Icons.lightbulb_outline_rounded,
    SparkPostType.SEEKING: Icons.search_rounded,
    SparkPostType.OFFERING: Icons.card_giftcard_rounded,
    SparkPostType.QUESTION: Icons.help_outline_rounded,
    SparkPostType.ANNOUNCEMENT: Icons.campaign_outlined,
  };

  // ============================================
  // INTENT / LOOKING FOR ICONS
  // ============================================

  /// Get icon for an intent key
  static IconData getIntentIcon(String key) {
    return _intentIcons[key] ?? Icons.explore_rounded;
  }

  /// Get color for an intent key
  static Color getIntentColor(String key) {
    return _intentColors[key] ?? const Color(0xFF9C27B0);
  }

  static const Map<String, IconData> _intentIcons = {
    'DATING': Icons.favorite_rounded,
    'FRIENDS': Icons.people_rounded,
    'COFOUNDER': Icons.rocket_launch_rounded,
    'PROJECT_PARTNER': Icons.handshake_rounded,
    'STUDY_GROUP': Icons.school_rounded,
    'HACKATHON_TEAM': Icons.code_rounded,
    'MENTOR': Icons.psychology_rounded,
    'MENTEE': Icons.spa_rounded,
    'JOB': Icons.work_rounded,
    'HIRE': Icons.person_search_rounded,
    'NETWORKING': Icons.hub_rounded,
  };

  static const Map<String, Color> _intentColors = {
    'DATING': Color(0xFFE91E63),
    'FRIENDS': Color(0xFF2196F3),
    'COFOUNDER': Color(0xFF673AB7),
    'PROJECT_PARTNER': Color(0xFF009688),
    'STUDY_GROUP': Color(0xFFFF9800),
    'HACKATHON_TEAM': Color(0xFF4CAF50),
    'MENTOR': Color(0xFF3F51B5),
    'MENTEE': Color(0xFF8BC34A),
    'JOB': Color(0xFF607D8B),
    'HIRE': Color(0xFF00BCD4),
    'NETWORKING': Color(0xFF9C27B0),
  };

  // ============================================
  // VIBE / GAME SECTION ICONS
  // ============================================

  static const IconData vibeCheck = Icons.sports_esports_rounded;
  static const IconData liveNow = Icons.whatshot_rounded;
  static const IconData trivia = Icons.emoji_events_rounded;
  static const IconData icebreaker = Icons.ac_unit_rounded;
  static const IconData wouldYouRather = Icons.chat_bubble_outline_rounded;
  static const IconData personality = Icons.psychology_rounded;
  static const IconData compatibility = Icons.favorite_border_rounded;
  static const IconData quickMatch = Icons.bolt_rounded;
  static const IconData timer = Icons.timer_outlined;
  static const IconData streak = Icons.local_fire_department_rounded;

  // ============================================
  // COMMON ACTION ICONS
  // ============================================

  static const IconData spark = Icons.bolt_rounded;
  static const IconData comment = Icons.chat_bubble_outline_rounded;
  static const IconData share = Icons.share_outlined;
  static const IconData bookmark = Icons.bookmark_border_rounded;
  static const IconData bookmarkFilled = Icons.bookmark_rounded;
  static const IconData more = Icons.more_horiz;
  static const IconData add = Icons.add_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsFilled = Icons.notifications_rounded;
  static const IconData search = Icons.search_rounded;

  // ============================================
  // NAVIGATION ICONS
  // ============================================

  static const IconData home = Icons.home_rounded;
  static const IconData homeOutlined = Icons.home_outlined;
  static const IconData discover = Icons.explore_rounded;
  static const IconData discoverOutlined = Icons.explore_outlined;
  static const IconData impact = Icons.hub_rounded;
  static const IconData impactOutlined = Icons.hub_outlined;
  static const IconData chat = Icons.chat_rounded;
  static const IconData chatOutlined = Icons.chat_outlined;
  static const IconData profile = Icons.person_rounded;
  static const IconData profileOutlined = Icons.person_outline_rounded;

  // ============================================
  // FILTER ICONS
  // ============================================

  static const IconData filterAll = Icons.auto_awesome_rounded;

  /// Get all filter chip configurations for SparkPostType
  static List<FilterChipConfig> getSparkFilterConfigs() {
    return [
      FilterChipConfig(
        label: 'All',
        icon: filterAll,
        type: null,
      ),
      ...SparkPostType.values.map((type) => FilterChipConfig(
            label: _sparkPostLabels[type] ?? type.name,
            icon: getSparkPostIcon(type),
            type: type,
          )),
    ];
  }

  static const Map<SparkPostType, String> _sparkPostLabels = {
    SparkPostType.IDEA: 'Ideas',
    SparkPostType.SEEKING: 'Seeking',
    SparkPostType.OFFERING: 'Offering',
    SparkPostType.QUESTION: 'Q&A',
    SparkPostType.ANNOUNCEMENT: 'Announcements',
  };
}

/// Configuration for filter chips
class FilterChipConfig {
  final String label;
  final IconData icon;
  final SparkPostType? type;

  const FilterChipConfig({
    required this.label,
    required this.icon,
    this.type,
  });
}
