import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/pages/home/home_service.dart';
import 'package:thittam1hub/pages/home/widgets/stories_bar.dart';
import 'package:thittam1hub/pages/home/widgets/streak_badge.dart';
import 'package:thittam1hub/pages/home/widgets/quick_poll_card.dart';
import 'package:thittam1hub/pages/home/widgets/spark_feed_card.dart';
import 'package:thittam1hub/pages/home/widgets/trending_topics.dart';
import 'package:thittam1hub/pages/home/widgets/create_post_fab.dart';
import 'package:thittam1hub/pages/home/widgets/comment_sheet.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/notification_item.dart';
import 'package:thittam1hub/utils/animations.dart' hide BrandedRefreshIndicator;
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';
import 'package:thittam1hub/widgets/thittam1hub_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final HomeService _homeService = HomeService();
  final SparkService _sparkService = SparkService();
  
  List<SparkPost> _posts = [];
  List<VibeGameItem> _polls = [];
  StreakData? _streakData;
  List<StoryItem> _stories = [];
  List<String> _trendingTags = [];
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  StreamSubscription? _notificationSubscription;
  final Set<String> _sparked = {};
  final ScrollController _scrollController = ScrollController();
  SparkPostType? _selectedFilter;
  
  @override
  void initState() {
    super.initState();
    _loadAllData();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToNotifications() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificationSubscription = SupabaseConfig.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (mounted) {
            final unread = data.where((n) => n['read'] == false).length;
            setState(() => _unreadNotificationCount = unread);
          }
        });
  }

  void _openCommentSheet(SparkPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        postId: post.id,
        initialCommentCount: post.commentCount,
      ),
    );
  }


  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _homeService.getStreakData(),
      _homeService.getStoriesData(),
      _homeService.getTrendingTags(),
      _sparkService.getSparkPosts(type: _selectedFilter),
      _homeService.getActivePolls(),
    ]);
    
    if (mounted) {
      setState(() {
        _streakData = results[0] as StreakData?;
        _stories = results[1] as List<StoryItem>;
        _trendingTags = results[2] as List<String>;
        _posts = results[3] as List<SparkPost>;
        _polls = results[4] as List<VibeGameItem>;
        _isLoading = false;
      });
    }
  }

  void _setFilter(SparkPostType? type) {
    if (_selectedFilter == type) return;
    setState(() => _selectedFilter = type);
    _loadAllData();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    // Force refresh from server, bypassing cache
    await _loadAllData();
  }

  void _onPostCreated() {
    _loadAllData();
  }

  List<Widget> _buildFeedItems() {
    final List<Widget> items = [];
    int pollIndex = 0;
    
    for (int i = 0; i < _posts.length; i++) {
      // Insert poll every 5 posts
      if (i > 0 && i % 5 == 0 && pollIndex < _polls.length) {
        items.add(
          FadeSlideTransition(
            delay: staggerDelay(items.length),
            child: QuickPollCard(
              poll: _polls[pollIndex],
              onVote: (optionIndex) async {
                await _homeService.submitPollVote(_polls[pollIndex].id, optionIndex);
                _loadAllData();
              },
            ),
          ),
        );
        pollIndex++;
      }
      
      // Insert trending topics every 10 posts
      if (i > 0 && i % 10 == 0 && _trendingTags.isNotEmpty) {
        items.add(
          FadeSlideTransition(
            delay: staggerDelay(items.length),
            child: TrendingTopics(
              tags: _trendingTags,
              onTagTap: (tag) {
                // TODO: Filter feed by tag
              },
            ),
          ),
        );
      }
      
      final post = _posts[i];
      items.add(
        FadeSlideTransition(
          delay: staggerDelay(items.length),
          child: SparkFeedCard(
            post: post,
            hasSparked: _sparked.contains(post.id),
            onDoubleTap: () async {
              HapticFeedback.lightImpact();
              final created = await _sparkService.toggleSparkOnce(post.id);
              if (mounted && created) {
                setState(() {
                  _sparked.add(post.id);
                  final index = _posts.indexWhere((p) => p.id == post.id);
                  if (index >= 0) {
                    _posts[index] = SparkPost(
                      id: post.id,
                      authorId: post.authorId,
                      authorName: post.authorName,
                      authorAvatar: post.authorAvatar,
                      type: post.type,
                      title: post.title,
                      content: post.content,
                      tags: post.tags,
                      sparkCount: post.sparkCount + 1,
                      commentCount: post.commentCount,
                      createdAt: post.createdAt,
                    );
                  }
                });
              }
            },
            onSparkTap: () async {
              HapticFeedback.lightImpact();
              final created = await _sparkService.toggleSparkOnce(post.id);
              if (mounted && created) {
                setState(() {
                  _sparked.add(post.id);
                  final index = _posts.indexWhere((p) => p.id == post.id);
                  if (index >= 0) {
                    _posts[index] = SparkPost(
                      id: post.id,
                      authorId: post.authorId,
                      authorName: post.authorName,
                      authorAvatar: post.authorAvatar,
                      type: post.type,
                      title: post.title,
                      content: post.content,
                      tags: post.tags,
                      sparkCount: post.sparkCount + 1,
                      commentCount: post.commentCount,
                      createdAt: post.createdAt,
                    );
                  }
                });
              }
            },
            onCommentTap: () => _openCommentSheet(post),
            onShareTap: () {
              // TODO: Share post
            },
          ),
        ),
      );
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: BrandedRefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Enhanced App Bar with Gradient
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 70,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [cs.surface, cs.surface.withValues(alpha: 0.95)]
                          : [cs.surface, cs.surfaceContainerLowest],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                    title: const Thittam1hubLogoInline(
                      iconSize: 22,
                    ),
                  ),
                ),
                actions: [
                  // Compact Streak Badge
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _isLoading
                        ? const StreakBadgeSkeleton()
                        : StreakBadge(
                            streakData: _streakData,
                            onTap: () async {
                              if (_streakData != null && !_streakData!.completedToday) {
                                HapticFeedback.mediumImpact();
                                await _homeService.completeStreakAction();
                                _loadAllData();
                              }
                            },
                          ),
                  ),
                  // Notification button with glassmorphism
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _GlassIconButton(
                      icon: Icons.notifications_outlined,
                      badgeCount: _unreadNotificationCount,
                      onPressed: () {
                        // TODO: Open notifications page
                      },
                    ),
                  ),
                  // Search button
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _GlassIconButton(
                      icon: Icons.search_rounded,
                      onPressed: () {
                        // TODO: Open search
                      },
                    ),
                  ),
                ],
              ),
              
              // Stories Bar
              SliverToBoxAdapter(
                child: _isLoading
                    ? const StoriesBarSkeleton()
                    : StoriesBar(
                        stories: _stories,
                        onStoryTap: (story) {
                          // TODO: Open story
                        },
                        onAddTap: () {
                          // TODO: Create story/post
                        },
                      ),
              ),
              
              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          icon: Icons.auto_awesome_rounded,
                          isSelected: _selectedFilter == null,
                          onTap: () => _setFilter(null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Ideas',
                          icon: Icons.lightbulb_outline_rounded,
                          isSelected: _selectedFilter == SparkPostType.IDEA,
                          onTap: () => _setFilter(SparkPostType.IDEA),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Seeking',
                          icon: Icons.search_rounded,
                          isSelected: _selectedFilter == SparkPostType.SEEKING,
                          onTap: () => _setFilter(SparkPostType.SEEKING),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Offering',
                          icon: Icons.card_giftcard_rounded,
                          isSelected: _selectedFilter == SparkPostType.OFFERING,
                          onTap: () => _setFilter(SparkPostType.OFFERING),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Q&A',
                          icon: Icons.help_outline_rounded,
                          isSelected: _selectedFilter == SparkPostType.QUESTION,
                          onTap: () => _setFilter(SparkPostType.QUESTION),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Announcements',
                          icon: Icons.campaign_outlined,
                          isSelected: _selectedFilter == SparkPostType.ANNOUNCEMENT,
                          onTap: () => _setFilter(SparkPostType.ANNOUNCEMENT),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Removed large streak card - now using compact badge in app bar
              
              // Feed Items
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                sliver: _isLoading
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FadeSlideTransition(
                            delay: staggerDelay(index),
                            child: const SparkFeedCardSkeleton(),
                          ),
                          childCount: 5,
                        ),
                      )
                    : _posts.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyFeedState(),
                          )
                        : SliverList(
                            delegate: SliverChildListDelegate(
                              _buildFeedItems(),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: CreatePostFab(
        onPostCreated: _onPostCreated,
      ),
    );
  }
}

/// Glass morphism icon button with optional badge
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    this.badgeCount = 0,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark 
              ? cs.surfaceContainerHighest.withValues(alpha: 0.8)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: cs.onSurface, size: 22),
            if (badgeCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: TextStyle(
                      color: cs.onError,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Modern empty state with gradient and illustration
class _EmptyFeedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.tertiary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.dynamic_feed_rounded,
                size: 56,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [cs.primary, cs.tertiary],
              ).createShader(bounds),
              child: Text(
                'Your Feed is Empty',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to share something amazing\nwith the community!',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // TODO: Open create post
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Post'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphism filter chip for post type filtering
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected 
              ? null 
              : isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : cs.outline.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
