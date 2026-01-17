import 'package:flutter/material.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';

class QuickPollCard extends StatefulWidget {
  final VibeGameItem poll;
  final Function(int) onVote;

  const QuickPollCard({
    Key? key,
    required this.poll,
    required this.onVote,
  }) : super(key: key);

  @override
  State<QuickPollCard> createState() => _QuickPollCardState();
}

class _QuickPollCardState extends State<QuickPollCard> {
  int? _selectedOption;
  bool _hasVoted = false;

  void _vote(int optionIndex) {
    if (_hasVoted) return;
    
    setState(() {
      _selectedOption = optionIndex;
      _hasVoted = true;
    });
    
    widget.onVote(optionIndex);
  }

  String _getTimeLeft() {
    final expiresAt = widget.poll.expiresAt;
    if (expiresAt == null) return '';
    
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final options = widget.poll.options;
    final totalVotes = widget.poll.participantCount ?? 0;
    
    // For demo, simulate vote percentages
    final percentages = options.length == 2
        ? [67, 33]
        : List.generate(options.length, (i) => (100 / options.length).round());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              cs.primaryContainer.withValues(alpha: 0.3),
              cs.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.poll, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        'QUICK POLL',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _getTimeLeft(),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Question
            Text(
              widget.poll.question,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Options
            ...List.generate(options.length, (index) {
              final option = options[index];
              final percentage = percentages[index];
              final isSelected = _selectedOption == index;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _vote(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Progress bar (shown after voting)
                        if (_hasVoted)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary.withValues(alpha: 0.2)
                                        : cs.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_hasVoted)
                                Text(
                                  '$percentage%',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 8),
            
            // Vote count
            Text(
              '$totalVotes votes${_hasVoted ? ' • You voted' : ''}',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickPollCardSkeleton extends StatelessWidget {
  const QuickPollCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surfaceContainerHighest,
        ),
      ),
    );
  }
}
