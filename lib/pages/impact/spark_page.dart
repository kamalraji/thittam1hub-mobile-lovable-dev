import 'package:flutter/material.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';

class SparkPage extends StatefulWidget {
  const SparkPage({Key? key}) : super(key: key);

  @override
  State<SparkPage> createState() => _SparkPageState();
}

class _SparkPageState extends State<SparkPage> {
  final SparkService _sparkService = SparkService();
  List<SparkPost> _allPosts = [];
  List<SparkPost> _filteredPosts = [];
  SparkPostType? _selectedFilter;
  bool _isLoading = true;
  final Set<String> _sparked = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts([SparkPostType? filter]) async {
    setState(() => _isLoading = true);
    final posts = await _sparkService.getSparkPosts(type: filter);
    if (mounted) {
      setState(() {
        _allPosts = posts;
        _filteredPosts = posts;
        _isLoading = false;
      });
    }
  }

  void _filterPosts(SparkPostType? type) {
    setState(() => _selectedFilter = type);
    _loadPosts(type);
  }

  void _showNewPostDialog() {
    showGlassBottomSheet(
      context: context,
      title: 'New Spark Post',
      child: NewSparkPostContent(
        onSubmit: (type, title, content, tags) async {
          await _sparkService.createSparkPost(
            type: type,
            title: title,
            content: content,
            tags: tags,
          );
          _loadPosts(_selectedFilter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          '💡 Spark Board',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showNewPostDialog,
            icon: Icon(Icons.add_circle_outline),
            label: Text('New Post'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('All'),
                      onSelected: (val) => _filterPosts(null),
                      selected: _selectedFilter == null,
                      selectedColor: cs.primary,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Ideas'),
                      onSelected: (val) => _filterPosts(SparkPostType.IDEA),
                      selected: _selectedFilter == SparkPostType.IDEA,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Seeking'),
                      onSelected: (val) => _filterPosts(SparkPostType.SEEKING),
                      selected: _selectedFilter == SparkPostType.SEEKING,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Offering'),
                      onSelected: (val) => _filterPosts(SparkPostType.OFFERING),
                      selected: _selectedFilter == SparkPostType.OFFERING,
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Q&A'),
                      onSelected: (val) => _filterPosts(SparkPostType.QUESTION),
                      selected: _selectedFilter == SparkPostType.QUESTION,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? ListView(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                      children: List.generate(4, (i) => FadeSlideTransition(
                        delay: staggerDelay(i),
                        child: const SparkPostSkeleton(),
                      )),
                    )
                  : _filteredPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 64, color: cs.onSurfaceVariant),
                              SizedBox(height: 16),
                              Text('No posts yet.', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: _showNewPostDialog,
                                child: Text('Create First Post'),
                              ),
                            ],
                          ),
                        )
                      : BrandedRefreshIndicator(
                          onRefresh: () => _loadPosts(_selectedFilter),
                          child: ListView.builder(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                            itemCount: _filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = _filteredPosts[index];
                              return FadeSlideTransition(
                                delay: staggerDelay(index),
                                child: SparkPostCard(
                                  post: post,
                                  hasSparked: _sparked.contains(post.id),
                                  onSpark: () async {
                                    final created = await _sparkService.toggleSparkOnce(post.id);
                                    if (!mounted) return;
                                    if (created) {
                                      setState(() {
                                        _sparked.add(post.id);
                                        _filteredPosts[index] = SparkPost(
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
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You already sparked this post')));
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content widget for New Spark Post glassmorphism sheet
class NewSparkPostContent extends StatefulWidget {
  final Function(SparkPostType, String, String, List<String>) onSubmit;

  const NewSparkPostContent({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<NewSparkPostContent> createState() => _NewSparkPostContentState();
}

class _NewSparkPostContentState extends State<NewSparkPostContent> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  SparkPostType _selectedType = SparkPostType.IDEA;
  List<String> _tags = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and content are required')),
      );
      return;
    }

    final cs = Theme.of(context).colorScheme;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        _selectedType,
        _titleController.text.trim(),
        _contentController.text.trim(),
        _tags,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: cs.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Text('Post Type', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SparkPostType.values.map((type) {
                final emoji = {
                  SparkPostType.IDEA: '💡',
                  SparkPostType.SEEKING: '🔍',
                  SparkPostType.OFFERING: '🎁',
                  SparkPostType.QUESTION: '❓',
                  SparkPostType.ANNOUNCEMENT: '📢',
                }[type];
                return ChoiceChip(
                  label: Text('$emoji ${type.name}'),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                  selectedColor: cs.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            Text('Tags', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add a tag',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle),
                  color: cs.primary,
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        ))
                    .toList(),
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Create Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Legacy NewSparkPostSheet kept for backward compatibility
class NewSparkPostSheet extends StatelessWidget {
  final Function(SparkPostType, String, String, List<String>) onSubmit;

  const NewSparkPostSheet({Key? key, required this.onSubmit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: NewSparkPostContent(onSubmit: onSubmit),
    );
  }
}

class SparkPostCard extends StatelessWidget {
  final SparkPost post;
  final bool hasSparked;
  final VoidCallback onSpark;

  const SparkPostCard({
    Key? key,
    required this.post,
    required this.hasSparked,
    required this.onSpark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final typeEmoji = {
      SparkPostType.IDEA: '💡 IDEA',
      SparkPostType.SEEKING: '🔍 SEEKING',
      SparkPostType.OFFERING: '🎁 OFFERING',
      SparkPostType.QUESTION: '❓ QUESTION',
      SparkPostType.ANNOUNCEMENT: '📢 ANNOUNCEMENT',
    }[post.type];

    final timeAgo = _formatTimeAgo(post.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(typeEmoji!, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(post.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: 12),
            Wrap(spacing: 8, children: post.tags.map((tag) => Chip(label: Text(tag))).toList()),
            SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: onSpark,
                  child: Row(children: [
                    Icon(Icons.bolt, color: hasSparked ? Colors.amber[800] : Colors.amber[700], size: 20),
                    SizedBox(width: 4),
                    Text('${post.sparkCount} sparks', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                ),
                SizedBox(width: 16),
                Icon(Icons.comment, color: cs.onSurfaceVariant, size: 20),
                SizedBox(width: 4),
                Text('${post.commentCount} comments', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Posted by ${post.authorName} • $timeAgo',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

class SparkPostSkeleton extends StatelessWidget {
  const SparkPostSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 80, color: cs.surfaceContainerHighest),
            SizedBox(height: 12),
            Container(height: 18, width: double.infinity, color: cs.surfaceContainerHighest),
            SizedBox(height: 12),
            Container(height: 12, width: double.infinity, color: cs.surfaceContainerHighest),
            SizedBox(height: 6),
            Container(height: 12, width: 200, color: cs.surfaceContainerHighest),
            SizedBox(height: 16),
            Row(
              children: [
                Container(height: 24, width: 60, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12))),
                SizedBox(width: 8),
                Container(height: 24, width: 60, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
