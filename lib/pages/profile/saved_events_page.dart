import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/saved_event.dart';
import 'package:thittam1hub/services/saved_events_service.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';

/// Saved Events page with filtering and reminders
class SavedEventsPage extends StatefulWidget {
  const SavedEventsPage({super.key});

  @override
  State<SavedEventsPage> createState() => _SavedEventsPageState();
}

class _SavedEventsPageState extends State<SavedEventsPage> {
  final _savedEventsService = SavedEventsService();
  
  List<SavedEvent> _savedEvents = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, upcoming, past, reminders

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    
    try {
      final events = await _savedEventsService.getSavedEvents(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _savedEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load saved events error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadSavedEvents(forceRefresh: true);
  }

  List<SavedEvent> get _filteredEvents {
    switch (_filter) {
      case 'upcoming':
        return _savedEvents.where((e) => e.isUpcoming).toList();
      case 'past':
        return _savedEvents.where((e) => e.isPast).toList();
      case 'reminders':
        return _savedEvents.where((e) => e.reminderEnabled).toList();
      default:
        return _savedEvents;
    }
  }

  Future<void> _unsaveEvent(SavedEvent event) async {
    final success = await _savedEventsService.unsaveEvent(event.eventId);
    if (success) {
      HapticFeedback.lightImpact();
      setState(() {
        _savedEvents.removeWhere((e) => e.id == event.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.eventName} removed from saved'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await _savedEventsService.saveEvent(event.eventId);
                _loadSavedEvents();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(SavedEvent event) async {
    final success = await _savedEventsService.toggleReminder(
      event.id,
      !event.reminderEnabled,
    );
    if (success) {
      HapticFeedback.lightImpact();
      setState(() {
        final index = _savedEvents.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          _savedEvents[index] = event.copyWith(
            reminderEnabled: !event.reminderEnabled,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Events'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                _FilterChip(
                  label: 'Upcoming',
                  isSelected: _filter == 'upcoming',
                  count: _savedEvents.where((e) => e.isUpcoming).length,
                  onTap: () => setState(() => _filter = 'upcoming'),
                ),
                _FilterChip(
                  label: 'Past',
                  isSelected: _filter == 'past',
                  onTap: () => setState(() => _filter = 'past'),
                ),
                _FilterChip(
                  label: 'With Reminders',
                  isSelected: _filter == 'reminders',
                  icon: Icons.notifications_active,
                  onTap: () => setState(() => _filter = 'reminders'),
                ),
              ],
            ),
          ),
          // Events list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                    ? _buildEmptyState()
                    : BrandedRefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return FadeSlideTransition(
                              delay: staggerDelay(index),
                              child: _SavedEventCard(
                                event: event,
                                onTap: () => context.push('/events/${event.eventId}'),
                                onToggleReminder: () => _toggleReminder(event),
                                onRemove: () => _unsaveEvent(event),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;

    String title;
    String subtitle;
    
    switch (_filter) {
      case 'upcoming':
        title = 'No upcoming saved events';
        subtitle = 'Save events you\'re interested in attending';
        break;
      case 'past':
        title = 'No past saved events';
        subtitle = 'Your past saved events will appear here';
        break;
      case 'reminders':
        title = 'No events with reminders';
        subtitle = 'Enable reminders on saved events to get notified';
        break;
      default:
        title = 'No saved events yet';
        subtitle = 'Save events you\'re interested in to find them here later!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.explore),
              label: const Text('Discover Events'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? count;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.count,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? cs.onPrimary : cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: isSelected ? cs.primary : cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onSelected: (_) {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}

class _SavedEventCard extends StatelessWidget {
  final SavedEvent event;
  final VoidCallback onTap;
  final VoidCallback onToggleReminder;
  final VoidCallback onRemove;

  const _SavedEventCard({
    required this.event,
    required this.onTap,
    required this.onToggleReminder,
    required this.onRemove,
  });

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final d = dt.toLocal();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(DateTime dt) {
    final d = dt.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Event thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: event.eventBannerUrl != null
                      ? Image.network(
                          event.eventBannerUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _PlaceholderImage(),
                        )
                      : _PlaceholderImage(),
                ),
                const SizedBox(width: 12),
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventName,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(event.eventStartDate)} • ${_formatTime(event.eventStartDate)}',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Status badge and reminder toggle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: event.isUpcoming
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : cs.outline.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.isUpcoming ? 'Upcoming' : 'Past',
                              style: context.textStyles.labelSmall?.copyWith(
                                color: event.isUpcoming
                                    ? AppColors.success
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (event.isUpcoming)
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onToggleReminder();
                              },
                              icon: Icon(
                                event.reminderEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                color: event.reminderEnabled
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                              tooltip: event.reminderEnabled
                                  ? 'Reminder on'
                                  : 'Set reminder',
                            ),
                        ],
                      ),
                    ],
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

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.event,
        size: 32,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
