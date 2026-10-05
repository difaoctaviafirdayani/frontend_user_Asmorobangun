import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Galeri Sanggar',
      body: AsyncView<List<GalleryItem>>(
        loader: () async => mapList((await api.get('/gallery'))['gallery'], GalleryItem.fromJson),
        builder: (context, items, _) {
          if (items.isEmpty) return const EmptyState('Belum ada foto galeri.', icon: Icons.photo_library_outlined);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final g = items[i];
              return AppCard(
                padding: EdgeInsets.zero,
                onTap: () => _openViewer(context, g),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: NetImage(src: g.image, width: double.infinity)),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext context, GalleryItem g) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cream100,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            InteractiveViewer(child: NetImage(src: g.image, width: double.infinity, fit: BoxFit.contain, radius: const BorderRadius.vertical(top: Radius.circular(18)))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (g.caption.isNotEmpty) ...[const SizedBox(height: 6), Text(g.caption, style: const TextStyle(color: AppColors.inkSoft))],
                const SizedBox(height: 4),
                Text(formatDate(g.date), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
