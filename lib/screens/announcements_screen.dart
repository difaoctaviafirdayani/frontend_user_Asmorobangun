import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pengumuman',
      body: AsyncView<List<Announcement>>(
        loader: () async => mapList((await api.get('/announcements'))['announcements'], Announcement.fromJson),
        builder: (context, items, _) {
          if (items.isEmpty) return const EmptyState('Belum ada pengumuman.', icon: Icons.campaign_outlined);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = items[i];
              return AppCard(
                padding: const EdgeInsets.all(12),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementDetailScreen(item: a))),
                child: Row(children: [
                  if (a.image != null && a.image!.isNotEmpty) ...[
                    NetImage(src: a.image, width: 64, height: 64, radius: BorderRadius.circular(12)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      TagChip(a.type, gold: true),
                      const SizedBox(height: 6),
                      Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(formatDate(a.date), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement item;
  const AnnouncementDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pengumuman',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (item.image != null && item.image!.isNotEmpty) ...[
          NetImage(src: item.image, height: 200, width: double.infinity, radius: BorderRadius.circular(16)),
          const SizedBox(height: 14),
        ],
        Align(alignment: Alignment.centerLeft, child: TagChip(item.type, gold: true)),
        const SizedBox(height: 8),
        Text(item.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.wood900)),
        const SizedBox(height: 4),
        Text(formatDate(item.date), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
        const SizedBox(height: 14),
        Text(item.body, style: const TextStyle(height: 1.55)),
      ]),
    );
  }
}
