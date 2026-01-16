import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:thittam1hub/models/user_ticket.dart';
import 'package:thittam1hub/services/ticket_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/utils/hero_animations.dart';

/// My Tickets page - Shows all user's event tickets
class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage>
    with SingleTickerProviderStateMixin {
  final _ticketService = TicketService();
  List<UserTicket> _allTickets = [];
  String _activeFilter = 'all';
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeFilter = ['upcoming', 'past', 'all'][_tabController.index];
        });
      }
    });
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final tickets = await _ticketService.getUserTickets(userId);
      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load tickets: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserTicket> get _filteredTickets {
    switch (_activeFilter) {
      case 'upcoming':
        return _allTickets
            .where((t) => t.isUpcoming || t.isOngoing)
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
      case 'past':
        return _allTickets.where((t) => t.isPast).toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
      default:
        return _allTickets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upcoming, size: 18),
                  const SizedBox(width: 6),
                  Text('Upcoming (${_allTickets.where((t) => t.isUpcoming || t.isOngoing).length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  Text('Past (${_allTickets.where((t) => t.isPast).length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list, size: 18),
                  const SizedBox(width: 6),
                  Text('All (${_allTickets.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 4,
              itemBuilder: (context, index) => FadeSlideTransition(
                delay: staggerDelay(index),
                child: const TicketCardSkeleton(),
              ),
            )
          : _filteredTickets.isEmpty
              ? _buildEmptyState(cs)
              : BrandedRefreshIndicator(
                  onRefresh: _loadTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _filteredTickets[index];
                      return FadeSlideTransition(
                        delay: staggerDelay(index),
                        child: _TicketCard(
                          ticket: ticket,
                          onTap: () => context.push(
                            '/profile/tickets/${ticket.registrationId}',
                            extra: ticket,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final message = _activeFilter == 'upcoming'
        ? 'No upcoming events'
        : _activeFilter == 'past'
            ? 'No past events yet'
            : 'No tickets found';
    final subtitle = _activeFilter == 'upcoming'
        ? 'Register for events to see your tickets here'
        : _activeFilter == 'past'
            ? 'Attended events will appear here'
            : 'Browse events and register to get started';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: context.textStyles.titleLarge?.bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Events'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern glassmorphism ticket card
class _TicketCard extends StatefulWidget {
  final UserTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ticket = widget.ticket;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate countdown for upcoming events
    final countdown = ticket.timeUntilStart;
    final showCountdown = ticket.isUpcoming && countdown.inDays < 7;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Hero(
          tag: HeroConfig.ticketCardTag(ticket.registrationId),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner with gradient overlay
                    _buildBanner(cs, ticket, showCountdown, countdown),

                    // Perforated divider
                    _buildPerforatedDivider(cs, isDark),

                    // Ticket info
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event name & status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.eventName,
                                  style: context.textStyles.titleMedium?.bold,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _StatusBadge(ticket: ticket),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Organization
                          Text(
                            ticket.organizationName,
                            style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Details row
                          Row(
                            children: [
                              _IconLabel(
                                icon: Icons.calendar_today_outlined,
                                label: DateFormat('MMM d, yyyy').format(ticket.startDate),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _IconLabel(
                                icon: ticket.modeIcon,
                                label: ticket.modeLabel,
                              ),
                              const Spacer(),
                              _IconLabel(
                                icon: Icons.confirmation_number_outlined,
                                label: ticket.quantity > 1 ? '${ticket.quantity} tickets' : '1 ticket',
                              ),
                            ],
                          ),

                          // Tier badge
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_activity, size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  ticket.tierName,
                                  style: context.textStyles.labelSmall?.withColor(cs.primary)?.bold,
                                ),
                                if (!ticket.isFree) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${ticket.currency} ${ticket.tierPrice.toStringAsFixed(0)}',
                                    style: context.textStyles.labelSmall?.withColor(cs.primary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(ColorScheme cs, UserTicket ticket, bool showCountdown, Duration countdown) {
    return Stack(
      children: [
        // Banner image
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            image: ticket.bannerUrl != null
                ? DecorationImage(
                    image: NetworkImage(ticket.bannerUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: ticket.bannerUrl == null
                ? LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Countdown badge
        if (showCountdown)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatCountdown(countdown),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Organization logo
        if (ticket.organizationLogo != null)
          Positioned(
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ticket.organizationLogo!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPerforatedDivider(ColorScheme cs, bool isDark) {
    return Stack(
      children: [
        // Left notch
        Positioned(
          left: -10,
          top: 0,
          bottom: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : cs.surfaceContainer,
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Right notch
        Positioned(
          right: -10,
          top: 0,
          bottom: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : cs.surfaceContainer,
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Dashed line
        Container(
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(
              30,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 2,
                  color: i.isEven
                      ? cs.outline.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCountdown(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final UserTicket ticket;

  const _StatusBadge({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ticket.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: ticket.statusColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ticket.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ticket.statusLabel,
            style: context.textStyles.labelSmall?.copyWith(
              color: ticket.statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon with label widget
class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Ticket card skeleton
class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner skeleton
          ShimmerLoading(
            width: double.infinity,
            height: 100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ShimmerLoading(
                        width: double.infinity,
                        height: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShimmerLoading(
                      width: 80,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ShimmerLoading(
                  width: 140,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    ShimmerLoading(
                      width: 100,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ShimmerLoading(
                      width: 60,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ShimmerLoading(
                  width: 100,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
