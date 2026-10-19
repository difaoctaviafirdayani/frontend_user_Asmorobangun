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
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Pengumuman terbaru seputar pendaftaran, jadwal, dan kegiatan Sanggar Asmorobangun.',
                    style: TextStyle(color: AppColors.wood800, height: 1.4),
                  ),
                );
              }
              return _AnnouncementCard(item: items[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement item;
  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wood700),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(color: AppColors.wood700, borderRadius: BorderRadius.circular(999)),
          child: Text(item.type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Text(item.title, style: headingStyle(size: 20)),
        const SizedBox(height: 4),
        Text(formatDateLong(item.date),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.wood800)),
        const SizedBox(height: 6),
        Text(item.body, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.wood800)),
      ]),
    );
  }
}