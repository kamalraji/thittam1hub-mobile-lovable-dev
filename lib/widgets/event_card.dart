import 'package:flutter/material.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final List<TicketTier> tiers;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const EventCard({
    super.key,
    required this.event,
    required this.tiers,
    required this.saved,
    required this.onTap,
    required this.onToggleSave,
  });

  String _formatDateRange(DateTime start, DateTime end) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final s = start.toLocal();
    final hour = s.hour % 12 == 0 ? 12 : s.hour % 12;
    final min = s.minute.toString().padLeft(2, '0');
    final ampm = s.hour < 12 ? 'AM' : 'PM';
    final datePart = '${months[s.month - 1]} ${s.day}';
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
    return '₹$lowest';
  }

  ImageProvider _imageProvider(String urlOrAsset) {
    if (urlOrAsset.isEmpty) {
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

    return TapScaleWidget(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - compact aspect ratio
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 2.1,
                  child: Image(
                    image: _imageProvider(event.branding.bannerUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                // Save button
                Positioned(
                  right: 6,
                  top: 6,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onToggleSave,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                          color: saved ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                // Badges
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Row(
                    children: [
                      _CompactBadge(icon: icon, label: label, color: clr),
                      const SizedBox(width: 4),
                      _CompactBadge(
                        label: event.category.displayName,
                        color: _categoryColor(event.category),
                      ),
                    ],
                  ),
                ),
                // Status badge
                if (event.status == EventStatus.ONGOING)
                  const Positioned(right: 6, bottom: 6, child: _LiveBadge())
                else if (event.status == EventStatus.PUBLISHED)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: _CompactBadge(label: 'Soon', color: Colors.orange),
                  ),
              ],
            ),
            // Info section - compact padding
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDateRange(event.startDate, event.endDate),
                          style: text.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Organization logo
                      Builder(builder: (_) {
                        final orgLogo = event.organization.logoUrl;
                        final hasLogo = orgLogo.isNotEmpty;
                        return CircleAvatar(
                          radius: 10,
                          backgroundColor: cs.surfaceContainerHighest,
                          backgroundImage: hasLogo ? _imageProvider(orgLogo) : null,
                          child: hasLogo ? null : Icon(Icons.apartment, size: 10, color: cs.onSurfaceVariant),
                        );
                      }),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.organization.name,
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (priceText.isNotEmpty) _PriceBadge(text: priceText),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBadge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const _CompactBadge({this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String text;
  const _PriceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFree = text.toLowerCase() == 'free';
    final bg = isFree ? AppColors.success.withValues(alpha: 0.12) : cs.surfaceContainerHighest;
    final border = isFree ? AppColors.success.withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.4);
    final fg = isFree ? AppColors.success : cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
