import 'package:flutter/material.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/theme.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final List<TicketTier> tiers;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const EventCard({super.key, required this.event, required this.tiers, required this.saved, required this.onTap, required this.onToggleSave});

  String _formatDateRange(DateTime start, DateTime end) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final s = start.toLocal();
    final hour = s.hour % 12 == 0 ? 12 : s.hour % 12;
    final min = s.minute.toString().padLeft(2, '0');
    final ampm = s.hour < 12 ? 'AM' : 'PM';
    final datePart = '${months[s.month - 1]} ${s.day}, ${s.year}';
    final timePart = '$hour:$min $ampm';
    return '$datePart • $timePart';
  }

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

  (IconData, Color, String) _modeBadge(EventMode mode) => switch (mode) {
        EventMode.ONLINE => (Icons.public, Colors.blue, 'Online'),
        EventMode.OFFLINE => (Icons.place, Colors.green, 'Offline'),
        EventMode.HYBRID => (Icons.group, Colors.purple, 'Hybrid'),
      };

  String _priceLabel(List<TicketTier> tiers) {
    if (tiers.isEmpty) return '';
    final prices = tiers.map((t) => t.price).where((p) => p >= 0).toList()..sort();
    if (prices.isEmpty) return '';
    if (prices.first == 0) return 'Free';
    final lowest = prices.first.toStringAsFixed(0);
    return 'From ₹$lowest';
  }

  ImageProvider _imageProvider(String urlOrAsset) {
    if (urlOrAsset.isEmpty) {
      // Fallback banner/logo
      return const NetworkImage('https://images.unsplash.com/photo-1540575467063-178a50c2df87');
    }
    if (urlOrAsset.startsWith('http')) return NetworkImage(urlOrAsset);
    return AssetImage(urlOrAsset);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, clr, label) = _modeBadge(event.mode);
    final priceText = _priceLabel(tiers);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Card(
        color: cs.surface,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    child: Image(image: _imageProvider(event.branding.bannerUrl), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? Colors.redAccent : Colors.white),
                      onPressed: onToggleSave,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Row(
                    children: [
                      _Badge(icon: icon, label: label.toUpperCase(), color: clr),
                      const SizedBox(width: 8),
                      _BadgeSmall(
                        label: event.category.displayName.toUpperCase(),
                        color: _categoryColor(event.category),
                      ),
                    ],
                  ),
                ),
                if (event.status == EventStatus.ONGOING)
                  const Positioned(right: 8, bottom: 8, child: _LiveNowBadge())
                else if (event.status == EventStatus.PUBLISHED)
                  const Positioned(right: 8, bottom: 8, child: _BadgeSmall(label: 'UPCOMING', color: Colors.orange)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(_formatDateRange(event.startDate, event.endDate), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Builder(builder: (_) {
                    final orgLogo = event.organization.logoUrl;
                    final hasLogo = orgLogo.isNotEmpty;
                    return CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      backgroundImage: hasLogo ? _imageProvider(orgLogo) : null,
                      child: hasLogo ? null : const Icon(Icons.apartment, size: 14, color: Colors.grey),
                    );
                  }),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.organization.name, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                  if (priceText.isNotEmpty) _PriceBadge(text: priceText),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700))]),
    );
  }
}

class _BadgeSmall extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeSmall({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
    );
  }
}

class _LiveNowBadge extends StatelessWidget {
  const _LiveNowBadge();
  @override
  Widget build(BuildContext context) {
    return _PulseBadge(label: 'LIVE NOW', color: AppColors.error);
  }
}

class _PulseBadge extends StatefulWidget {
  final String label;
  final Color color;
  const _PulseBadge({required this.label, required this.color});

  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
      child: Row(children: [
        ScaleTransition(
          scale: _scale,
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 6),
        Text(widget.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: widget.color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String text;
  const _PriceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final isFree = text.toLowerCase() == 'free';
    final bg = isFree ? AppColors.success.withValues(alpha: 0.12) : AppColors.card;
    final border = isFree ? AppColors.success.withValues(alpha: 0.5) : AppColors.border;
    final fg = isFree ? AppColors.success : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
