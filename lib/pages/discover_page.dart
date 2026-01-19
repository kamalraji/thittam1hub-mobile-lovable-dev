import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/event_card.dart';
import 'package:thittam1hub/services/event_service.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/utils/result.dart';
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';
import 'package:thittam1hub/nav.dart';
import 'package:thittam1hub/utils/icon_mappings.dart';

class DiscoverPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialMode;
  
  const DiscoverPage({super.key, this.initialCategory, this.initialMode});

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
    _initializeFilters();
    _loadEvents();
  }
  
  void _initializeFilters() {
    if (widget.initialCategory != null) {
      _selectedCategory = _parseCategory(widget.initialCategory!);
    }
    if (widget.initialMode != null) {
      _selectedMode = _parseMode(widget.initialMode!);
    }
  }
  
  EventCategory? _parseCategory(String category) {
    final upper = category.toUpperCase();
    try {
      return EventCategory.values.firstWhere(
        (e) => e.name == upper,
      );
    } catch (_) {
      return null;
    }
  }
  
  EventMode? _parseMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'online':
        return EventMode.ONLINE;
      case 'offline':
        return EventMode.OFFLINE;
      case 'hybrid':
        return EventMode.HYBRID;
      default:
        return null;
    }
  }
  
  void _updateUrl() {
    String? categoryStr;
    if (_selectedCategory != null) {
      categoryStr = _selectedCategory!.name.toLowerCase();
    }
    String? modeStr;
    if (_selectedMode != null) {
      modeStr = _selectedMode!.name.toLowerCase();
    }
    final url = AppRoutes.discoverWithFilters(category: categoryStr, mode: modeStr);
    context.replace(url);
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
    // Show featured categories inline, with "More" button for full list
    final featuredCats = <EventCategory?>[
      null, // All
      EventCategory.HACKATHON,
      EventCategory.WORKSHOP,
      EventCategory.CONFERENCE,
      EventCategory.MEETUP,
      EventCategory.WEBINAR,
      EventCategory.NETWORKING,
      EventCategory.STARTUP_PITCH,
    ];
    
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (_, i) {
          // Last item is "More" button
          if (i == featuredCats.length) {
            return GestureDetector(
              onTap: _showCategorySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.more_horiz_rounded, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final cat = featuredCats[i];
          final selected = _selectedCategory == cat;
          final label = cat == null ? 'All' : cat.displayName;
          final icon = cat == null 
              ? IconMappings.filterAll 
              : IconMappings.getEventCategoryIcon(cat);
          final color = cat == null 
              ? cs.primary 
              : IconMappings.getEventCategoryColor(cat);
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
              _updateUrl();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? color : cs.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: selected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: featuredCats.length + 1, // +1 for "More" button
      ),
    );
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFilterSheet(
        selectedCategory: _selectedCategory,
        onCategorySelected: (cat) {
          setState(() => _selectedCategory = cat);
          _updateUrl();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _modeToggles() {
    final cs = Theme.of(context).colorScheme;
    Widget buildBtn(String label, IconData icon, EventMode mode) {
      final selected = _selectedMode == mode;
      return GestureDetector(
        onTap: () {
          setState(() => _selectedMode = selected ? null : mode);
          _updateUrl();
        },
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: BrandedRefreshIndicator(
          onRefresh: () => _loadEvents(forceRefresh: true),
          child: CustomScrollView(
          slivers: [
            // Compact App Bar - 56px height
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              expandedHeight: AppLayout.appBarHeight,
              toolbarHeight: AppLayout.toolbarHeight,
              automaticallyImplyLeading: false,
              title: Text('Discover', style: textTheme.titleLarge),
            ),
            // Filters Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
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
            ),
            // Events List
            SliverFillRemaining(
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
        ),
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

/// Bottom sheet for selecting event categories with grouped display
class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final EventCategory? selectedCategory;
  final void Function(EventCategory?) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groupedCategories = IconMappings.getGroupedEventCategories();
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  'Select Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (selectedCategory != null)
                  TextButton(
                    onPressed: () => onCategorySelected(null),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Category list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: groupedCategories.length,
              itemBuilder: (context, index) {
                final groupName = groupedCategories.keys.elementAt(index);
                final categories = groupedCategories[groupName]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                      child: Text(
                        groupName,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((config) {
                        final isSelected = selectedCategory == config.category;
                        final color = config.category != null
                            ? IconMappings.getEventCategoryColor(config.category!)
                            : cs.primary;
                        
                        return GestureDetector(
                          onTap: () => onCategorySelected(config.category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? color : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? color : cs.outline.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  config.icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  config.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
