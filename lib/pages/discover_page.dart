import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/event_card.dart';
import 'package:thittam1hub/services/event_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final EventService _eventService = EventService();
  EventCategory? _selectedCategory; // null = All
  EventMode? _selectedMode; // null = all
  late TabController _tabController; // 0 = All Events, 1 = Past Events
  final Set<String> _savedEventIds = {};
  List<Event> _events = [];
  bool _isLoading = true;
  Map<String, List<TicketTier>> _tiersByEvent = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getAllEvents();
      Map<String, List<TicketTier>> tiers = {};
      if (events.isNotEmpty) {
        final ids = events.map((e) => e.id).toList();
        tiers = await _eventService.getTicketTiersForEvents(ids);
      }
      if (mounted) {
        setState(() {
          _events = events;
          _tiersByEvent = tiers;
          _isLoading = false;
        });
        // If All tab is empty but Past has items, auto-switch to Past for better UX
        final allNow = _filtered();
        if (allNow.isEmpty) {
          // Temporarily compute past list
          final now = DateTime.now();
          final past = _events.where((e) => e.endDate.isBefore(now)).toList();
          if (past.isNotEmpty && _tabController.index != 1) {
            _tabController.index = 1;
            setState(() {});
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (_tabController.index == 1 && e.endDate.isAfter(now)) return false; // Past Events tab
      // For All Events tab, exclude past events
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
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search events in Thittam1Hub...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => setState(() => _searchController.clear()))
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _categoryChips() {
    final cats = [null, EventCategory.HACKATHON, EventCategory.WORKSHOP, EventCategory.CONFERENCE, EventCategory.MEETUP, EventCategory.WEBINAR, EventCategory.SEMINAR, EventCategory.COMPETITION];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final selected = _selectedCategory == cat;
          final label = cat == null ? 'All' : cat.displayName;
          return ChoiceChip(
            label: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? Colors.white : AppColors.textPrimary)),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: AppColors.card,
            shape: StadiumBorder(side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : AppColors.border)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: cats.length,
      ),
    );
  }

  Widget _modeToggles() {
    Widget buildBtn(String label, IconData icon, EventMode mode) {
      final selected = _selectedMode == mode;
      return GestureDetector(
        onTap: () => setState(() => _selectedMode = selected ? null : mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : AppColors.border),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    return Row(children: [
      buildBtn('Online', Icons.public, EventMode.ONLINE),
      const SizedBox(width: 8),
      buildBtn('Offline', Icons.place, EventMode.OFFLINE),
      const SizedBox(width: 8),
      buildBtn('Hybrid', Icons.group, EventMode.HYBRID),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _searchBar(context),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: _categoryChips()),
              const SizedBox(height: 8),
              _modeToggles(),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(999)),
                child: TabBar(
                  controller: _tabController,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                  indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(999)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textPrimary,
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'All Events'), Tab(text: 'Past Events')],
                  onTap: (_) => setState(() {}),
                ),
              ),
            ]),
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
                  onRefresh: _loadEvents,
                  onToggleSave: (id) => setState(() {
                    if (_savedEventIds.contains(id)) {
                      _savedEventIds.remove(id);
                    } else {
                      _savedEventIds.add(id);
                    }
                  }),
                ),
                _EventsTab(
                  key: const ValueKey('tab_past'),
                  isLoading: _isLoading,
                  events: _filteredForTab(1),
                  tiersByEvent: _tiersByEvent,
                  savedEventIds: _savedEventIds,
                  onRefresh: _loadEvents,
                  onToggleSave: (id) => setState(() {
                    if (_savedEventIds.contains(id)) {
                      _savedEventIds.remove(id);
                    } else {
                      _savedEventIds.add(id);
                    }
                  }),
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
      if (tabIndex == 1 && e.endDate.isAfter(now)) return false; // Past tab
      if (tabIndex == 0 && e.endDate.isBefore(now)) return false; // All tab excludes past
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
  const _EventsTab({super.key, required this.isLoading, required this.events, required this.tiersByEvent, required this.savedEventIds, required this.onRefresh, required this.onToggleSave});

  final bool isLoading;
  final List<Event> events;
  final Map<String, List<TicketTier>> tiersByEvent;
  final Set<String> savedEventIds;
  final Future<void> Function() onRefresh;
  final void Function(String id) onToggleSave;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: events.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(child: Icon(Icons.event_busy, size: 64, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                Center(child: Text('No events found', style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 8),
                Center(child: Text('Try adjusting your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted))),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: events.length,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = events[i];
                return EventCard(
                  event: e,
                  tiers: tiersByEvent[e.id] ?? const [],
                  saved: savedEventIds.contains(e.id),
                  onTap: () => context.push('/events/${e.id}'),
                  onToggleSave: () => onToggleSave(e.id),
                );
              },
            ),
    );
  }
}
