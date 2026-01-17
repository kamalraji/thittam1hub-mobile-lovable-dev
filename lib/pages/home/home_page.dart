import 'package:flutter/material.dart';
import 'package:thittam1hub/pages/home/home_service.dart';
import 'package:thittam1hub/pages/home/widgets/stories_bar.dart';
import 'package:thittam1hub/pages/home/widgets/streak_card.dart';
import 'package:thittam1hub/pages/home/widgets/quick_poll_card.dart';
import 'package:thittam1hub/pages/home/widgets/spark_feed_card.dart';
import 'package:thittam1hub/pages/home/widgets/trending_topics.dart';
import 'package:thittam1hub/pages/home/widgets/create_post_fab.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/utils/animations.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeService _homeService = HomeService();
  final SparkService _sparkService = SparkService();
  
  List<SparkPost> _posts = [];
  List<VibeGameItem> _polls = [];
  StreakData? _streakData;
  List<StoryItem> _stories = [];
  List<String> _trendingTags = [];
  
  bool _isLoading = true;
  final Set<String> _sparked = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            onCommentTap: () {
              // TODO: Open comments sheet
            },
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
    
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: BrandedRefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: cs.surface,
                elevation: 0,
                title: Text(
                  '✨ Feed',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: cs.onSurface),
                    onPressed: () {
                      // TODO: Open search
                    },
                  ),
                  SizedBox(width: 8),
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
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.dynamic_feed_outlined, size: 64, color: cs.onSurfaceVariant),
                                  SizedBox(height: 16),
                                  Text(
                                    'No posts yet',
                                    style: textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Be the first to share something!',
                                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
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
