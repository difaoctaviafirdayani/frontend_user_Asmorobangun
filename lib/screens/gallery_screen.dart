import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../repositories/gallery_repository.dart';
import '../viewmodels/gallery_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/load_status_view.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => GalleryViewModel(c.read<GalleryRepository>())..load(),
      child: const _GalleryView(),
    );
  }
}

class _GalleryView extends StatelessWidget {
  const _GalleryView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GalleryViewModel>();
    return AppScaffold(
      title: 'Galeri Sanggar',
      backgroundColor: Colors.white,
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (context) {
          final items = vm.data!;
          if (items.isEmpty) return const EmptyState('Belum ada foto galeri.', icon: Icons.photo_library_outlined);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 255,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _card(context, items[i]),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, GalleryItem g) {
    return GestureDetector(
      onTap: () => _openViewer(context, g),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.wood700, width: 1.5),
        ),
        child: Column(children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: NetImage(src: g.image, width: double.infinity, radius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 10),
          Text(g.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.wood700)),
          if (g.caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Expanded(
              child: Text(g.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.wood700, height: 1.3)),
            ),
          ],
        ]),
      ),
    );
  }

  void _openViewer(BuildContext context, GalleryItem g) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.wood700, width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            InteractiveViewer(
              child: NetImage(
                src: g.image,
                width: double.infinity,
                fit: BoxFit.contain,
                radius: const BorderRadius.vertical(top: Radius.circular(20.5)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.wood700)),
                if (g.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(g.caption, style: const TextStyle(color: AppColors.wood700)),
                ],
                const SizedBox(height: 4),
                Text(formatDateLong(g.date), style: const TextStyle(color: AppColors.wood700, fontSize: 12)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}