// lib/ui/ui_bundle.dart
import 'package:flutter/material.dart';
import '../models/influencer.dart';
import '../models/influencer_routine.dart';

class RoutineCard extends StatelessWidget {
  final InfluencerRoutine routine;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const RoutineCard({super.key, required this.routine, this.onTap, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)});

  @override
  Widget build(BuildContext context) {
    final thumb = (routine.thumbnailUrl.isNotEmpty)
        ? routine.thumbnailUrl
        : 'https://via.placeholder.com/150x100?text=No+Image';

    return Padding(
      padding: padding,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 90,
                child: Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0x11000000),
                    child: Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title.isEmpty ? '제목 미지정' : routine.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const _MetaChip(icon: Icons.timer, label: '시간'),
                          _MetaChip(icon: Icons.bar_chart, label: '난이도 ${routine.difficulty}'),
                          if (routine.provider.isNotEmpty)
                            _MetaChip(icon: Icons.play_circle_fill, label: routine.provider),
                        ],
                      ),
                      if (routine.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        TagWrap(tags: routine.tags, dense: true),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class InfluencerTile extends StatelessWidget {
  final Influencer influencer;
  final VoidCallback? onTap;
  final VoidCallback? onOpenChannel;
  final EdgeInsetsGeometry padding;

  const InfluencerTile({super.key, required this.influencer, this.onTap, this.onOpenChannel, this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).colorScheme.surface,
        leading: CircleAvatar(child: Text(influencer.name.isNotEmpty ? influencer.name[0] : '?')),
        title: Text(influencer.name),
        subtitle: Text('@${influencer.handle} • ${influencer.platform} • 팔로워 ${influencer.followers}'),
        trailing: IconButton(icon: const Icon(Icons.link), tooltip: '채널 열기', onPressed: onOpenChannel),
        onTap: onTap,
      ),
    );
  }
}

class TagWrap extends StatelessWidget {
  final List<String> tags;
  final bool dense;
  final void Function(String tag)? onTap;

  const TagWrap({super.key, required this.tags, this.onTap, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final spacing = dense ? 6.0 : 8.0;
    final runSpacing = dense ? 6.0 : 8.0;

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final t in tags)
          ActionChip(
            label: Text('#$t'),
            onPressed: onTap == null ? null : () => onTap!(t),
            visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
            materialTapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
          )
      ],
    );
  }
}
