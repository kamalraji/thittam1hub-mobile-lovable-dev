import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/pages/home/home_service.dart';
import 'package:thittam1hub/pages/home/widgets/stories_bar.dart';
import 'package:thittam1hub/pages/home/widgets/streak_card.dart';
import 'package:thittam1hub/pages/home/widgets/quick_poll_card.dart';
import 'package:thittam1hub/pages/home/widgets/spark_feed_card.dart';
import 'package:thittam1hub/pages/home/widgets/trending_topics.dart';
import 'package:thittam1hub/pages/home/widgets/create_post_fab.dart';
import 'package:thittam1hub/pages/home/widgets/comment_sheet.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/notification_item.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/utils/date_utils.dart';
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';

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
  String? _userName;
  
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  StreamSubscription? _notificationSubscription;
  final Set<String> _sparked = {};
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _greetingAnimController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _subscribeToNotifications();
    _loadUserName();
    
    _greetingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _waveAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _greetingAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationSubscription?.cancel();
    _greetingAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) {
      final profile = await SupabaseConfig.client
          .from('impact_profiles')
          .select('full_name')
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted && profile != null) {
        setState(() {
          _userName = (profile['full_name'] as String?)?.split(' ').first;
        });
      }
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
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _homeService.getStreakData(),
      _homeService.getStoriesData(),
      _homeService.getTrendingTags(),
      _sparkService.getSparkPosts(),
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

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
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
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _waveAnimation.value,
                              child: Text(
                                getGreetingEmoji(),
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _userName != null 
                              ? '${getGreeting()}, $_userName'
                              : getGreeting(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
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
              
              // Streak Card (if streak is at risk)
              if (_streakData != null && !_streakData!.completedToday)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: FadeSlideTransition(
                      child: StreakCard(
                        streakData: _streakData!,
                        onActionTap: () async {
                          HapticFeedback.mediumImpact();
                          await _homeService.completeStreakAction();
                          _loadAllData();
                        },
                      ),
                    ),
                  ),
                ),
              
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: cs.onSurface, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
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
