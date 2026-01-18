import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
import 'package:thittam1hub/nav.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart' hide BrandedRefreshIndicator;
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';
import 'package:thittam1hub/widgets/thittam1hub_logo.dart';

class HomePage extends StatefulWidget {
  final String? initialFilter;

  const HomePage({Key? key, this.initialFilter}) : super(key: key);

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
  // Filter removed - show all posts

  // Pagination state
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  String? _nextCursor;
  static const double _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _subscribeToNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Scroll listener for infinite scroll pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _loadMoreThreshold) {
      _loadMorePosts();
    }
  }

  /// Load more posts for infinite scroll
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);

    final result = await _sparkService.getSparkPostsPaginated();

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _hasMorePosts = result.hasMore;
        _nextCursor = result.nextCursor;
        _isLoadingMore = false;
      });
    }
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
    setState(() {
      _isLoading = true;
      _posts = [];
      _hasMorePosts = true;
      _nextCursor = null;
    });

    final results = await Future.wait([
      _homeService.getStreakData(),
      _homeService.getStoriesData(),
      _homeService.getTrendingTags(),
      _sparkService.getSparkPostsPaginated(),
      _homeService.getActivePolls(),
    ]);

    if (mounted) {
      final postsResult = results[3] as ({List<SparkPost> posts, bool hasMore, String? nextCursor});
      setState(() {
        _streakData = results[0] as StreakData?;
        _stories = results[1] as List<StoryItem>;
        _trendingTags = results[2] as List<String>;
        _posts = postsResult.posts;
        _hasMorePosts = postsResult.hasMore;
        _nextCursor = postsResult.nextCursor;
        _polls = results[4] as List<VibeGameItem>;
        _isLoading = false;
      });
    }
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
                await _homeService.submitPollVote(
                    _polls[pollIndex].id, optionIndex);
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

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: BrandedRefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Compact App Bar - 56px height
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                expandedHeight: AppLayout.appBarHeight,
                toolbarHeight: AppLayout.toolbarHeight,
                title: const Thittam1hubLogoInline(iconSize: 20),
                actions: [
                  // Compact Streak Badge
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _isLoading
                        ? const StreakBadgeSkeleton()
                        : StreakBadge(
                            streakData: _streakData,
                            onTap: () async {
                              if (_streakData != null &&
                                  !_streakData!.completedToday) {
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
                        context.push(AppRoutes.notifications);
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

              // Small spacing after stories

              // Feed Items
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom +
                      AppLayout.bottomContentPadding,
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
                            child: _CreativeFeedEmptyState(),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final feedItems = _buildFeedItems();

                                // Show loading indicator at end
                                if (index == feedItems.length) {
                                  return _LoadMoreIndicator(
                                    isLoading: _isLoadingMore,
                                    hasMore: _hasMorePosts,
                                  );
                                }

                                return feedItems[index];
                              },
                              childCount: _buildFeedItems().length +
                                  (_hasMorePosts ? 1 : 0),
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
              ? cs.surfaceContainerHighest.withOpacity(0.8)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outline.withOpacity(0.2),
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

/// Loading indicator for infinite scroll pagination
class _LoadMoreIndicator extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;

  const _LoadMoreIndicator({
    required this.isLoading,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: cs.outline, size: 28),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up!',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

/// Creative animated empty state for the feed
class _CreativeFeedEmptyState extends StatefulWidget {
  const _CreativeFeedEmptyState();

  @override
  State<_CreativeFeedEmptyState> createState() =>
      _CreativeFeedEmptyStateState();
}

class _CreativeFeedEmptyStateState extends State<_CreativeFeedEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated floating circles illustration
            SizedBox(
              height: 160,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Container(
                      width: 120 * _pulseAnimation.value,
                      height: 120 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            cs.primary.withOpacity(0.15),
                            cs.primary.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating circles
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Large center circle
                        Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [cs.primary, cs.tertiary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        // Small floating circles
                        Transform.translate(
                          offset: Offset(-60, _floatAnimation.value * 0.6 - 20),
                          child: _FloatingDot(
                            size: 24,
                            color: cs.secondary.withOpacity(0.7),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(65, _floatAnimation.value * 0.8 + 10),
                          child: _FloatingDot(
                            size: 20,
                            color: Colors.orange.withOpacity(0.7),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(-40, _floatAnimation.value * 0.4 + 40),
                          child: _FloatingDot(
                            size: 16,
                            color: Colors.pink.withOpacity(0.6),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(50, _floatAnimation.value * 0.5 - 35),
                          child: _FloatingDot(
                            size: 12,
                            color: Colors.green.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gradient title
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [cs.primary, cs.tertiary],
              ).createShader(bounds),
              child: Text(
                'The spark starts with you',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle hint
            Text(
              'Tap + to share your first thought',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Animated arrow pointing to FAB
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_floatAnimation.value * 2, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: cs.primary.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: cs.primary.withOpacity(0.4),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: cs.primary.withOpacity(0.2),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  final double size;
  final Color color;

  const _FloatingDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
