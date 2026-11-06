import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../repositories/announcement_repository.dart';
import '../viewmodels/announcement_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/load_status_view.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AnnouncementViewModel(c.read<AnnouncementRepository>())..load(),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  const _AnnouncementsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();
    return AppScaffold(
      title: 'Pengumuman',
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (context) {
          final items = vm.data!;
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