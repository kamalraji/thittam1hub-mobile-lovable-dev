import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/event_card.dart';
import 'package:thittam1hub/services/event_service.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/utils/result.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final EventService _eventService = EventService();
  EventCategory? _selectedCategory;
  EventMode? _selectedMode;
  late TabController _tabController;
  final Set<String> _savedEventIds = {};
  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<TicketTier>> _tiersByEvent = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _eventService.getAllEvents(forceRefresh: forceRefresh);

    switch (result) {
      case Success(data: final events):
        debugPrint('📅 Loaded ${events.length} events');
        for (final e in events) {
          debugPrint('  - ${e.name}: ${e.startDate} to ${e.endDate} (${e.status})');
        }
        
        Map<String, List<TicketTier>> tiers = {};
        if (events.isNotEmpty) {
          final ids = events.map((e) => e.id).toList();
          final tiersResult = await _eventService.getTicketTiersForEvents(ids);
          if (tiersResult case Success(data: final tiersData)) {
            tiers = tiersData;
          }
        }
        
        if (mounted) {
          setState(() {
            _events = events;
            _tiersByEvent = tiers;
            _isLoading = false;
          });
        }

      case Failure(message: final msg):
        if (mounted) {
          setState(() {
            _errorMessage = msg;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: _loadEvents,
              ),
            ),
          );
        }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Event> _filtered() {
    final now = DateTime.now();
    final query = _searchController.text.trim().toLowerCase();
    return _events.where((e) {
      if (_tabController.index == 1 && e.endDate.isAfter(now)) return false;
      if (_tabController.index == 0 && e.endDate.isBefore(now)) return false;
      if (_selectedCategory != null && e.category != _selectedCategory) return false;
      if (_selectedMode != null && e.mode != _selectedMode) return false;
      if (query.isNotEmpty) {
        final t = '${e.name} ${e.description ?? ''} ${e.organization.name}'.toLowerCase();
        if (!t.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Widget _searchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search events...',
        hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 18),
                onPressed: () => setState(() => _searchController.clear()),
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: cs.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        isDense: true,
      ),
    );
  }

  Widget _categoryChips() {
    final cs = Theme.of(context).colorScheme;
    final cats = [null, EventCategory.HACKATHON, EventCategory.WORKSHOP, EventCategory.CONFERENCE, EventCategory.MEETUP, EventCategory.WEBINAR, EventCategory.SEMINAR, EventCategory.COMPETITION];
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final selected = _selectedCategory == cat;
          final label = cat == null ? 'All' : cat.displayName;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? cs.primary : cs.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: cats.length,
      ),
    );
  }

  Widget _modeToggles() {
    final cs = Theme.of(context).colorScheme;
    Widget buildBtn(String label, IconData icon, EventMode mode) {
      final selected = _selectedMode == mode;
      return GestureDetector(
        onTap: () => setState(() => _selectedMode = selected ? null : mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: selected ? cs.onPrimary : cs.onSurface),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(children: [
      buildBtn('Online', Icons.public, EventMode.ONLINE),
      const SizedBox(width: 6),
      buildBtn('Offline', Icons.place, EventMode.OFFLINE),
      const SizedBox(width: 6),
      buildBtn('Hybrid', Icons.group, EventMode.HYBRID),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBar(context),
                const SizedBox(height: 8),
                _categoryChips(),
                const SizedBox(height: 6),
                _modeToggles(),
                const SizedBox(height: 8),
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    indicator: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: cs.onPrimary,
                    unselectedLabelColor: cs.onSurface,
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'All Events'),
                      Tab(text: 'Past Events'),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _EventsTab(
                  key: const ValueKey('tab_all'),
                  isLoading: _isLoading,
                  events: _filteredForTab(0),
                  tiersByEvent: _tiersByEvent,
                  savedEventIds: _savedEventIds,
                  onRefresh: () => _loadEvents(forceRefresh: true),
                  onToggleSave: (id) => setState(() {
                    if (_savedEventIds.contains(id)) {
                      _savedEventIds.remove(id);
                    } else {
                      _savedEventIds.add(id);
                    }
                  }),
                  hasPastEvents: _events.any((e) => e.endDate.isBefore(DateTime.now())),
                  onViewPastEvents: () => setState(() => _tabController.index = 1),
                  errorMessage: _errorMessage,
                ),
                _EventsTab(
                  key: const ValueKey('tab_past'),
                  isLoading: _isLoading,
                  events: _filteredForTab(1),
                  tiersByEvent: _tiersByEvent,
                  savedEventIds: _savedEventIds,
                  onRefresh: () => _loadEvents(forceRefresh: true),
                  onToggleSave: (id) => setState(() {
                    if (_savedEventIds.contains(id)) {
                      _savedEventIds.remove(id);
                    } else {
                      _savedEventIds.add(id);
                    }
                  }),
                  isPastTab: true,
                  errorMessage: _errorMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on _DiscoverPageState {
  List<Event> _filteredForTab(int tabIndex) {
    final now = DateTime.now();
    final query = _searchController.text.trim().toLowerCase();
    return _events.where((e) {
      if (tabIndex == 1 && e.endDate.isAfter(now)) return false;
      if (tabIndex == 0 && e.endDate.isBefore(now)) return false;
      if (_selectedCategory != null && e.category != _selectedCategory) return false;
      if (_selectedMode != null && e.mode != _selectedMode) return false;
      if (query.isNotEmpty) {
        final t = '${e.name} ${e.description ?? ''} ${e.organization.name}'.toLowerCase();
        if (!t.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    super.key,
    required this.isLoading,
    required this.events,
    required this.tiersByEvent,
    required this.savedEventIds,
    required this.onRefresh,
    required this.onToggleSave,
    this.hasPastEvents = false,
    this.onViewPastEvents,
    this.isPastTab = false,
    this.errorMessage,
  });

  final bool isLoading;
  final List<Event> events;
  final Map<String, List<TicketTier>> tiersByEvent;
  final Set<String> savedEventIds;
  final Future<void> Function() onRefresh;
  final void Function(String id) onToggleSave;
  final bool hasPastEvents;
  final VoidCallback? onViewPastEvents;
  final bool isPastTab;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, index) => FadeSlideTransition(
          delay: staggerDelay(index),
          child: const EventCardSkeleton(),
        ),
      );
    }

    // Show error state when there's an error
    if (errorMessage != null) {
      return BrandedRefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(child: Icon(Icons.cloud_off, size: 48, color: cs.error)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.error),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      );
    }

    return BrandedRefreshIndicator(
      onRefresh: onRefresh,
      child: events.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Center(child: Icon(Icons.event_busy, size: 48, color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    isPastTab ? 'No past events' : 'No upcoming events',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurface),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    isPastTab ? 'Events you attended will appear here' : 'Try adjusting your filters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (!isPastTab && hasPastEvents && onViewPastEvents != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: onViewPastEvents,
                      icon: Icon(Icons.history, size: 18, color: cs.primary),
                      label: Text(
                        'View past events',
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: events.length,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final e = events[i];
                return FadeSlideTransition(
                  delay: staggerDelay(i),
                  child: EventCard(
                    event: e,
                    tiers: tiersByEvent[e.id] ?? const [],
                    saved: savedEventIds.contains(e.id),
                    onTap: () => context.push('/events/${e.id}', extra: e),
                    onToggleSave: () => onToggleSave(e.id),
                  ),
                );
              },
            ),
    );
  }
}
