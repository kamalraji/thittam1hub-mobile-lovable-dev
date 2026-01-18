import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/services/media_upload_service.dart';
import 'package:thittam1hub/services/giphy_service.dart';
import 'package:thittam1hub/widgets/gif_picker_sheet.dart';
import 'package:thittam1hub/models/post_poll.dart';
import 'package:thittam1hub/theme.dart';

/// Compact content widget for New Spark Post with upload options
class NewSparkPostContent extends StatefulWidget {
  final Future<void> Function(
    SparkPostType type,
    String title,
    String content,
    List<String> tags, {
    String? imageUrl,
    String? gifUrl,
    String? pollId,
  }) onSubmit;

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

  // Image upload state
  final _mediaUploadService = MediaUploadService();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  // GIF state
  String? _selectedGifUrl;
  static const String _giphyApiKey = 'GlVGYHkr3WSBnllca54iNt0yFbjz7L65'; // Free tier key

  // Poll state
  bool _showPollCreator = false;
  List<TextEditingController> _pollOptionControllers = [];
  Duration _pollDuration = const Duration(hours: 24);

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
    _tags = [_postTypeOptions[_selectedType]!.tag];
    _pollOptionControllers = [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    for (final c in _pollOptionControllers) {
      c.dispose();
    }
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

  void _clearMedia() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedGifUrl = null;
      _showPollCreator = false;
      _selectedMediaType = null;
    });
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    _clearMedia();
    
    try {
      final result = await _mediaUploadService.pickImage();
      if (result != null) {
        setState(() {
          _selectedImageBytes = result.bytes;
          _selectedImageName = result.name;
          _selectedMediaType = 'image';
        });
      }
    } on ImageValidationError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _pickGif() async {
    HapticFeedback.lightImpact();
    _clearMedia();
    
    final gif = await showModalBottomSheet<GiphyGif>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GifPickerSheet(
        giphyApiKey: _giphyApiKey,
        onGifSelected: (g) => Navigator.pop(context, g),
      ),
    );
    
    if (gif != null && mounted) {
      setState(() {
        _selectedGifUrl = gif.fullUrl;
        _selectedMediaType = 'gif';
      });
    }
  }

  void _showPollCreatorToggle() {
    HapticFeedback.lightImpact();
    _clearMedia();
    setState(() {
      _showPollCreator = true;
      _selectedMediaType = 'poll';
      // Reset poll options
      for (final c in _pollOptionControllers) {
        c.clear();
      }
      _pollDuration = const Duration(hours: 24);
    });
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length > 2) {
      HapticFeedback.lightImpact();
      setState(() {
        _pollOptionControllers[index].dispose();
        _pollOptionControllers.removeAt(index);
      });
    }
  }

  Future<void> _addLink() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔗 Link preview coming soon!'), duration: Duration(seconds: 2)),
    );
  }

  String? _validatePoll() {
    final poll = PostPoll(
      options: _pollOptionControllers.map((c) => c.text).toList(),
      duration: _pollDuration,
    );
    return poll.validate();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Write something to share!')),
      );
      return;
    }

    // Validate poll if active
    if (_showPollCreator) {
      final pollError = _validatePoll();
      if (pollError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pollError)),
        );
        return;
      }
    }

    final cs = Theme.of(context).colorScheme;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    
    try {
      // Upload image if selected
      String? imageUrl;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _mediaUploadService.uploadImage(
          bytes: _selectedImageBytes!,
          fileName: _selectedImageName!,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
        setState(() => _isUploadingImage = false);
      }
      
      // Use content as both title and content
      final content = _contentController.text.trim();
      final title = content.length > 50 ? '${content.substring(0, 47)}...' : content;
      
      // TODO: Create poll if _showPollCreator and get pollId
      String? pollId;
      
      await widget.onSubmit(
        _selectedType, 
        title, 
        content, 
        _tags,
        imageUrl: imageUrl,
        gifUrl: _selectedGifUrl,
        pollId: pollId,
      );
      
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
      if (mounted) setState(() {
        _isSubmitting = false;
        _isUploadingImage = false;
      });
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
            
            // Media Preview
            _buildMediaPreview(),
            
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
                  onTap: _showPollCreatorToggle,
                ),
                _UploadButton(
                  icon: Icons.link_rounded,
                  label: 'Link',
                  isSelected: _selectedMediaType == 'link',
                  onTap: _addLink,
                ),
              ],
            ),
            
            // Poll Creator (if active)
            if (_showPollCreator) _buildPollCreator(),
            
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

  Widget _buildMediaPreview() {
    final cs = Theme.of(context).colorScheme;
    
    // Image preview
    if (_selectedImageBytes != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _selectedImageBytes!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Progress overlay during upload
            if (_isUploadingImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Remove button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: _clearMedia,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // GIF preview
    if (_selectedGifUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _selectedGifUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: cs.surfaceContainerHighest,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            ),
            // GIF badge
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('GIF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            // Remove button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: _clearMedia,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildPollCreator() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.poll_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text('Create Poll', style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                )),
                const Spacer(),
                GestureDetector(
                  onTap: _clearMedia,
                  child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Duration selector
            Text('Duration', style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: PollDuration.options.map((option) {
                final isSelected = _pollDuration == option.duration;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _pollDuration = option.duration);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            
            // Poll options
            ...List.generate(_pollOptionControllers.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pollOptionControllers[i],
                      style: textTheme.bodySmall,
                      decoration: InputDecoration(
                        hintText: 'Option ${i + 1}',
                        hintStyle: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_pollOptionControllers.length > 2) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removePollOption(i),
                      child: Icon(Icons.remove_circle_outline, size: 18, color: cs.error),
                    ),
                  ],
                ],
              ),
            )),
            
            // Add option button
            if (_pollOptionControllers.length < 4)
              GestureDetector(
                onTap: _addPollOption,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('Add option', style: textTheme.labelSmall?.copyWith(color: cs.primary)),
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
                fontWeight: isAdded ? FontWeight.w600 : FontWeight.w500,
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
