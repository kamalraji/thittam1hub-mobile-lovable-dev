import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/services/event_service.dart';
import 'package:thittam1hub/utils/hero_animations.dart';
import 'package:thittam1hub/utils/result.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final Event? event; // Pass event for immediate hero display
  
  const EventDetailPage({
    super.key,
    required this.eventId,
    this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventService _eventService = EventService();
  Event? _event;
  List<TicketTier> _tiers = [];
  bool _isLoading = true;
  bool _aboutExpanded = false;

  @override
  void initState() {
    super.initState();
    // Use passed event for immediate display (enables smooth hero)
    if (widget.event != null) {
      _event = widget.event;
      _isLoading = false;
    }
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    // Only show loading if we don't have an event yet
    if (_event == null) {
      setState(() => _isLoading = true);
    }
    try {
      final eventResult = await _eventService.getEventById(widget.eventId);
      
      Event? event;
      if (eventResult case Success(:final data)) {
        event = data;
      } else if (eventResult case Failure(:final message)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
      
      List<TicketTier> tiers = [];
      if (event != null) {
        final tiersResult = await _eventService.getTicketTiers(widget.eventId);
        if (tiersResult case Success(:final data)) {
          tiers = data;
        }
      }
      
      if (mounted) {
        setState(() {
          _event = event;
          _tiers = tiers;
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TicketTier> _availableTiersNow() {
    final now = DateTime.now();
    final list = _tiers.where((t) {
      final withinStart = t.saleStart == null || !now.isBefore(t.saleStart!);
      final withinEnd = t.saleEnd == null || !now.isAfter(t.saleEnd!);
      final hasStock = t.quantity == null || t.soldCount < t.quantity!;
      return t.isActive && withinStart && withinEnd && hasStock;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  (String label, double? min, double? max) _priceRangeLabel(List<TicketTier> tiers) {
    if (tiers.isEmpty) return ('', null, null);
    final prices = tiers.map((t) => t.price).where((p) => p >= 0).toList()..sort();
    if (prices.isEmpty) return ('', null, null);
    final minP = prices.first;
    final maxP = prices.last;
    if (minP == 0 && maxP == 0) return ('Free', minP, maxP);
    if (minP == 0 && maxP > 0) return ('Free – ₹${maxP.toStringAsFixed(0)}', minP, maxP);
    if (minP == maxP) return ('₹${minP.toStringAsFixed(0)}', minP, maxP);
    return ('₹${minP.toStringAsFixed(0)} – ₹${maxP.toStringAsFixed(0)}', minP, maxP);
  }

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

  String _formatDateRange(DateTime start, DateTime end) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final s = start.toLocal();
    final e = end.toLocal();
    final sHour = s.hour % 12 == 0 ? 12 : s.hour % 12;
    final sMin = s.minute.toString().padLeft(2, '0');
    final sAmPm = s.hour < 12 ? 'AM' : 'PM';
    final eHour = e.hour % 12 == 0 ? 12 : e.hour % 12;
    final eMin = e.minute.toString().padLeft(2, '0');
    final eAmPm = e.hour < 12 ? 'AM' : 'PM';
    final datePart = '${months[s.month - 1]} ${s.day}, ${s.year}';
    return '$datePart • $sHour:$sMin $sAmPm - $eHour:$eMin $eAmPm';
  }

  (IconData, Color, String) _modeBadge(EventMode mode) => switch (mode) {
        EventMode.ONLINE => (Icons.public, Colors.blue, 'Online'),
        EventMode.OFFLINE => (Icons.place, Colors.green, 'Offline'),
        EventMode.HYBRID => (Icons.group, Colors.purple, 'Hybrid'),
      };

  Color _categoryColor(EventCategory category) => switch (category) {
        EventCategory.HACKATHON => AppColors.violet500,
        EventCategory.WORKSHOP => AppColors.amber500,
        EventCategory.CONFERENCE => AppColors.rose500,
        EventCategory.MEETUP => AppColors.emerald500,
        EventCategory.WEBINAR => AppColors.pink500,
        EventCategory.COMPETITION => AppColors.indigo500,
        EventCategory.SEMINAR => AppColors.teal500,
        EventCategory.CULTURAL_FEST => AppColors.fuchsia500,
        EventCategory.SPORTS_EVENT => AppColors.red500,
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final e = _event;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop())),
        body: const Center(child: Text('Event not found')),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, clr, modeLabel) = _modeBadge(e.mode);

    final available = _availableTiersNow();
    final priceTiers = available.isNotEmpty ? available : _tiers;
    final (priceLabel, _, __) = _priceRangeLabel(priceTiers);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
            actions: [
              IconButton(icon: const Icon(Icons.ios_share, color: Colors.white), onPressed: () {}),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16, end: 16),
              title: TextHero(
                tag: HeroConfig.eventTitleTag(widget.eventId),
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              background: Stack(fit: StackFit.expand, children: [
                AnimatedHero(
                  tag: HeroConfig.eventBannerTag(widget.eventId),
                  child: _BannerImage(urlOrAsset: e.branding.bannerUrl),
                ),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.5), Colors.black.withValues(alpha: 0.7)]))),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Row(children: [
                    _PillBadge(icon: icon, label: modeLabel, color: clr),
                    const SizedBox(width: 8),
                    _SmallBadge(label: e.category.displayName, color: _categoryColor(e.category)),
                    const Spacer(),
                    if (priceLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
                        child: Text(priceLabel, style: text.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Organizer Card (top)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline)),
                  child: Row(children: [
                    CircleAvatar(radius: 22, backgroundColor: Colors.white, backgroundImage: _imageProvider(e.organization.logoUrl)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(e.organization.name, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                        if (e.organization.verificationStatus == 'VERIFIED')
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.success.withValues(alpha: 0.5))), child: Row(children: const [Icon(Icons.verified, size: 16, color: AppColors.success), SizedBox(width: 4), Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success))])),
                      ]),
                      const SizedBox(height: 2),
                      Text('Hosted by @${e.organization.slug}', style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ])),
                    if (e.status == EventStatus.ONGOING)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)), child: Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('LIVE NOW', style: text.labelMedium?.copyWith(color: AppColors.error, fontWeight: FontWeight.w800)),
                      ])),
                  ]),
                ),
                const SizedBox(height: 16),
                // Info chips row
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _InfoChip(icon: Icons.calendar_today, label: _formatDate(e.startDate)),
                  _InfoChip(icon: Icons.access_time, label: _formatTime(e.startDate)),
                  _InfoChip(icon: icon, label: modeLabel),
                  if (e.capacity != null) _InfoChip(icon: Icons.people_alt, label: '${e.capacity} seats'),
                ]),
                const SizedBox(height: 16),
                // Description
                if ((e.description ?? '').isNotEmpty) ...[
                  Text('About', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: Text(e.description!, style: text.bodyLarge, maxLines: 3, overflow: TextOverflow.ellipsis),
                    secondChild: Text(e.description!, style: text.bodyLarge),
                    crossFadeState: _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded),
                    icon: Icon(_aboutExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).colorScheme.primary),
                    label: Text(_aboutExpanded ? 'Show less' : 'Read more', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
                const SizedBox(height: 8),
                // Organizer section
                Text('Organizer', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    CircleAvatar(radius: 24, backgroundColor: Colors.white, backgroundImage: _imageProvider(e.organization.logoUrl)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(e.organization.name, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                        if (e.organization.verificationStatus == 'VERIFIED') const Icon(Icons.verified, size: 18, color: AppColors.success),
                      ]),
                      const SizedBox(height: 2),
                      Text('@${e.organization.slug}', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                    ])),
                    IconButton(onPressed: () => _showComingSoon(context), icon: const Icon(Icons.chevron_right, color: AppColors.textMuted)),
                  ]),
                ),
                const SizedBox(height: 24),
                // Tickets header and range
                Row(children: [
                  Text('Tickets', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (priceLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
                      child: Text(priceLabel, style: text.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 12),
                // Ticket tiers list
                ..._tiers.map((t) {
                  final isAvailable = available.contains(t);
                  final soldOut = t.quantity != null && t.soldCount >= t.quantity!;
                  final priceText = t.price == 0 ? 'Free' : '₹${t.price.toStringAsFixed(0)}';
                  return Opacity(
                    opacity: isAvailable ? 1 : 0.6,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(t.name, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            if (soldOut) _Chip(label: 'Sold out', color: AppColors.error)
                            else if (!isAvailable) _Chip(label: 'Unavailable', color: AppColors.warning),
                          ]),
                          if ((t.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(t.description!, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                          ],
                          if (t.quantity != null) ...[
                            const SizedBox(height: 8),
                            _CapacityBar(total: t.quantity!, sold: t.soldCount),
                          ],
                        ])),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(priceText, style: text.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: isAvailable ? () => _showComingSoon(context) : null,
                            style: ButtonStyle(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
                            child: const Row(children: [Icon(Icons.confirmation_number, size: 18, color: Colors.white), SizedBox(width: 6), Text('Select')]),
                          ),
                        ]),
                      ]),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outline))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Price', style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
              Text(priceLabel.isEmpty ? '—' : priceLabel, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ]),
          ),
          switch (e.status) {
            EventStatus.COMPLETED => FilledButton(
              onPressed: null,
              style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))), padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
              child: const Row(children: [Icon(Icons.event_busy, color: Colors.white), SizedBox(width: 8), Text('Event Ended')]),
            ),
            EventStatus.ONGOING => FilledButton(
              onPressed: () => _handleJoinEvent(e),
              style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))), padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
              child: const Row(children: [Icon(Icons.play_circle, color: Colors.white), SizedBox(width: 8), Text('Event is Live')]),
            ),
            _ => FilledButton(
              onPressed: () => _showComingSoon(context),
              style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))), padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
              child: const Row(children: [Icon(Icons.confirmation_number, color: Colors.white), SizedBox(width: 8), Text('Register Now')]),
            )
          }
        ]),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket selection flow coming soon')));
  }

  void _handleJoinEvent(Event e) {
    // Placeholder for joining logic (e.g., open meeting URL or embedded stream)
    // We don't have a meeting URL field yet; show a helpful message.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joining the live event... (coming soon)')));
  }
}

class _BannerImage extends StatelessWidget {
  final String urlOrAsset;
  const _BannerImage({required this.urlOrAsset});
  @override
  Widget build(BuildContext context) {
    if (urlOrAsset.startsWith('http')) {
      return Image.network(urlOrAsset, fit: BoxFit.cover);
    }
    return Image.asset(urlOrAsset, fit: BoxFit.cover);
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PillBadge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800))]),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
      child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  final int total;
  final int sold;
  const _CapacityBar({required this.total, required this.sold});
  @override
  Widget build(BuildContext context) {
    final remaining = (total - sold).clamp(0, total);
    final pct = total == 0 ? 0.0 : sold / total;
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 8,
          child: Stack(children: [
            Container(width: double.infinity, color: Theme.of(context).colorScheme.surfaceContainerHighest),
            FractionallySizedBox(widthFactor: pct.clamp(0.0, 1.0), child: Container(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25))),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      Text('$remaining of $total left', style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
    ]);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppColors.textMuted), const SizedBox(width: 6), Text(label, style: text.labelLarge)]),
    );
  }
}

ImageProvider _imageProvider(String urlOrAsset) {
  if (urlOrAsset.startsWith('http')) return NetworkImage(urlOrAsset);
  return AssetImage(urlOrAsset);
}
