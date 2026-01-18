import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/theme.dart';

/// Compact content widget for New Spark Post with upload options
class NewSparkPostContent extends StatefulWidget {
  final Function(SparkPostType, String, String, List<String>) onSubmit;

  const NewSparkPostContent({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<NewSparkPostContent> createState() => _NewSparkPostContentState();
}

class _NewSparkPostContentState extends State<NewSparkPostContent> {
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  SparkPostType _selectedType = SparkPostType.IDEA;
  List<String> _tags = [];
  bool _isSubmitting = false;
  String? _selectedMediaType; // 'image', 'gif', 'poll', 'link'

  // Event-based suggested tags
  static const List<String> _eventTags = [
    'devcon', 'hackathon', 'workshop', 'meetup', 'webinar', 'startup'
  ];

  // Post type options as tags
  static const Map<SparkPostType, _PostTypeOption> _postTypeOptions = {
    SparkPostType.IDEA: _PostTypeOption(Icons.lightbulb_rounded, 'idea', Color(0xFFF59E0B)),
    SparkPostType.SEEKING: _PostTypeOption(Icons.search_rounded, 'seeking', Color(0xFF8B5CF6)),
    SparkPostType.OFFERING: _PostTypeOption(Icons.card_giftcard_rounded, 'offering', Color(0xFF10B981)),
    SparkPostType.QUESTION: _PostTypeOption(Icons.help_rounded, 'question', Color(0xFF3B82F6)),
    SparkPostType.ANNOUNCEMENT: _PostTypeOption(Icons.campaign_rounded, 'announce', Color(0xFFEC4899)),
  };

  @override
  void initState() {
    super.initState();
    // Add default type tag
    _tags = [_postTypeOptions[_selectedType]!.tag];
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final normalizedTag = tag.toLowerCase().replaceAll('#', '').trim();
    if (normalizedTag.isNotEmpty && !_tags.contains(normalizedTag)) {
      HapticFeedback.lightImpact();
      setState(() => _tags.add(normalizedTag));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    // Prevent removing type tag
    final isTypeTag = _postTypeOptions.values.any((opt) => opt.tag == tag);
    if (isTypeTag) return;
    setState(() => _tags.remove(tag));
  }

  void _selectType(SparkPostType type) {
    HapticFeedback.selectionClick();
    final oldTypeTag = _postTypeOptions[_selectedType]!.tag;
    final newTypeTag = _postTypeOptions[type]!.tag;
    setState(() {
      _selectedType = type;
      _tags = _tags.map((t) => t == oldTypeTag ? newTypeTag : t).toList();
      if (!_tags.contains(newTypeTag)) {
        _tags.insert(0, newTypeTag);
      }
    });
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    setState(() => _selectedMediaType = 'image');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📷 Image upload coming soon!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _pickGif() async {
    HapticFeedback.lightImpact();
    setState(() => _selectedMediaType = 'gif');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎬 GIF picker coming soon!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _showPollCreator() async {
    HapticFeedback.lightImpact();
    setState(() => _selectedMediaType = 'poll');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📊 Poll creation coming soon!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _addLink() async {
    HapticFeedback.lightImpact();
    setState(() => _selectedMediaType = 'link');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔗 Link preview coming soon!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Write something to share!')),
      );
      return;
    }

    final cs = Theme.of(context).colorScheme;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    
    try {
      // Use content as both title and content for simplicity
      final content = _contentController.text.trim();
      final title = content.length > 50 ? '${content.substring(0, 47)}...' : content;
      
      await widget.onSubmit(_selectedType, title, content, _tags);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Posted!'),
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
            // Post Type Selector (compact chips)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _postTypeOptions.entries.map((entry) {
                  final isSelected = _selectedType == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CompactTypeChip(
                      icon: entry.value.icon,
                      label: entry.value.tag,
                      color: entry.value.color,
                      isSelected: isSelected,
                      onTap: () => _selectType(entry.key),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Content Field (compact)
            TextField(
              controller: _contentController,
              maxLines: 3,
              maxLength: 280,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                counterStyle: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Upload Options Row
            Row(
              children: [
                _UploadButton(
                  icon: Icons.image_rounded,
                  label: 'Photo',
                  isSelected: _selectedMediaType == 'image',
                  onTap: _pickImage,
                ),
                _UploadButton(
                  icon: Icons.gif_box_rounded,
                  label: 'GIF',
                  isSelected: _selectedMediaType == 'gif',
                  onTap: _pickGif,
                ),
                _UploadButton(
                  icon: Icons.poll_rounded,
                  label: 'Poll',
                  isSelected: _selectedMediaType == 'poll',
                  onTap: _showPollCreator,
                ),
                _UploadButton(
                  icon: Icons.link_rounded,
                  label: 'Link',
                  isSelected: _selectedMediaType == 'link',
                  onTap: _addLink,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Event Tags (suggested)
            Text('Add tags', style: textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._eventTags.map((tag) => _SuggestedTag(
                  tag: tag,
                  isAdded: _tags.contains(tag),
                  onTap: () => _tags.contains(tag) ? _removeTag(tag) : _addTag(tag),
                )),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Custom tag input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: textTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Custom tag...',
                      hintStyle: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      prefixText: '#',
                      prefixStyle: textTheme.bodySmall?.copyWith(color: cs.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (value) => _addTag(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _addTag(_tagController.text),
                  icon: Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            // Current tags display
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags.map((tag) {
                  final isTypeTag = _postTypeOptions.values.any((opt) => opt.tag == tag);
                  final typeEntry = _postTypeOptions.entries.firstWhere(
                    (e) => e.value.tag == tag,
                    orElse: () => _postTypeOptions.entries.first,
                  );
                  
                  return Chip(
                    label: Text('#$tag', style: textTheme.labelSmall?.copyWith(
                      color: isTypeTag ? typeEntry.value.color : cs.primary,
                    )),
                    deleteIcon: isTypeTag ? null : Icon(Icons.close, size: 14),
                    onDeleted: isTypeTag ? null : () => _removeTag(tag),
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: (isTypeTag ? typeEntry.value.color : cs.primary).withValues(alpha: 0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                    : Text('Post', style: textTheme.labelLarge?.copyWith(color: cs.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostTypeOption {
  final IconData icon;
  final String tag;
  final Color color;
  const _PostTypeOption(this.icon, this.tag, this.color);
}

class _CompactTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactTypeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? color : cs.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '#$label',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isSelected ? Border.all(color: cs.primary, width: 1) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedTag extends StatelessWidget {
  final String tag;
  final bool isAdded;
  final VoidCallback onTap;

  const _SuggestedTag({
    required this.tag,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAdded ? cs.primary.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isAdded ? cs.primary : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$tag',
              style: TextStyle(
                fontSize: 11,
                color: isAdded ? cs.primary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isAdded) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 12, color: cs.primary),
            ],
          ],
        ),
      ),
    );
  }
}
