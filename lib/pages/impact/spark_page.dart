import 'package:flutter/material.dart';
import 'package:thittam1hub/supabase/spark_service.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NewSparkPostSheet(
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
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '💡 Spark Board',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showNewPostDialog,
            icon: Icon(Icons.add_circle_outline),
            label: Text('New Post'),
            style: TextButton.styleFrom(foregroundColor: Color(0xFF8B5CF6)),
          ),
        ],
      ),
      body: Column(
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
                    selectedColor: Color(0xFF8B5CF6),
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
                ? Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text('No posts yet.', style: TextStyle(color: Colors.grey[600])),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: _showNewPostDialog,
                              child: Text('Create First Post'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          return SparkPostCard(
                            post: post,
                            hasSparked: _sparked.contains(post.id),
                            onSpark: () async {
                              final created = await _sparkService.toggleSparkOnce(post.id);
                              if (!mounted) return;
                              if (created) {
                                setState(() {
                                  _sparked.add(post.id);
                                  // Optimistic UI update
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class NewSparkPostSheet extends StatefulWidget {
  final Function(SparkPostType, String, String, List<String>) onSubmit;

  const NewSparkPostSheet({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<NewSparkPostSheet> createState() => _NewSparkPostSheetState();
}

class _NewSparkPostSheetState extends State<NewSparkPostSheet> {
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
            backgroundColor: Color(0xFF8B5CF6),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New Spark Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Post Type', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  selectedColor: Color(0xFF8B5CF6).withValues(alpha: 0.2),
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
            Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: Color(0xFF8B5CF6),
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
                  backgroundColor: Color(0xFF8B5CF6),
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
            Text(typeEmoji!, style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(post.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
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
                    Text('${post.sparkCount} sparks', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ),
                SizedBox(width: 16),
                Icon(Icons.comment, color: Colors.grey[600], size: 20),
                SizedBox(width: 4),
                Text('${post.commentCount} comments', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Posted by ${post.authorName} • $timeAgo',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
