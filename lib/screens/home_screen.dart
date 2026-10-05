import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'announcements_screen.dart';
import 'articles_screen.dart';
import 'facilities_screen.dart';
import 'gallery_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  /// Pindah tab dari shell: 1 = Fasilitas, 2 = Forum.
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.wood900,
        foregroundColor: AppColors.cream100,
        elevation: 0,
        title: Image.asset('assets/images/logo-gold.png', height: 30),
        actions: [searchAction(context)],
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: NetImage(
            src: '/uploads/site_images/sanggar-utama.jpg',
            height: 170,
            width: double.infinity,
            radius: BorderRadius.circular(16),
          ),
        ),
        SectionHeader('Berita & pengumuman', onSeeAll: () => _push(context, const AnnouncementsScreen())),
        _announcements(context),
        SectionHeader('Artikel terbaru', onSeeAll: () => _push(context, const ArticlesScreen())),
        _featuredArticle(context),
        SectionHeader('Layanan sanggar', onSeeAll: () => onNavigate(1)),
        _facilities(context),
        SectionHeader('Galeri sanggar', onSeeAll: () => _push(context, const GalleryScreen())),
        _gallery(context),
        const SectionHeader('Lokasi sanggar'),
        _location(context),
        const SectionHeader('Forum diskusi'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            child: Column(children: [
              const Text(
                'Punya pertanyaan atau mau berbagi pengalaman soal sanggar? Gabung diskusi warga dan alumni kelas di sini.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => onNavigate(2),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Masuk ke Forum'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _announcements(BuildContext context) {
    return AsyncView<List<Announcement>>(
      loader: () async => mapList((await api.get('/announcements'))['announcements'], Announcement.fromJson),
      builder: (context, items, _) {
        if (items.isEmpty) return const EmptyState('Belum ada pengumuman.');
        return SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length > 8 ? 8 : items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final a = items[i];
              return SizedBox(
                width: 230,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () => _push(context, AnnouncementDetailScreen(item: a)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    NetImage(src: a.image ?? 'sanggar-tari.jpg', height: 104, width: double.infinity),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TagChip(a.type, gold: true),
                        const SizedBox(height: 6),
                        Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(formatDate(a.date), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _featuredArticle(BuildContext context) {
    return AsyncView<Article?>(
      loader: () async {
        final res = await api.get('/articles', query: {'limit': '1'});
        return res['featured'] is Map<String, dynamic> ? Article.fromJson(res['featured'] as Map<String, dynamic>) : null;
      },
      builder: (context, a, _) {
        if (a == null) return const EmptyState('Belum ada artikel.');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            onTap: () => _push(context, ArticleDetailScreen(slug: a.slug)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NetImage(src: a.image, height: 155, width: double.infinity),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TagChip(a.category, gold: true),
                  const SizedBox(height: 8),
                  Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(a.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _facilities(BuildContext context) {
    return AsyncView<List<Facility>>(
      loader: () async => mapList((await api.get('/facilities'))['facilities'], Facility.fromJson),
      builder: (context, items, _) => Column(children: [
        for (final f in items)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: FacilityTile(facility: f),
          ),
      ]),
    );
  }

  Widget _gallery(BuildContext context) {
    return AsyncView<List<GalleryItem>>(
      loader: () async => mapList((await api.get('/gallery'))['gallery'], GalleryItem.fromJson),
      builder: (context, items, _) {
        if (items.isEmpty) return const EmptyState('Belum ada foto galeri.');
        return SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final g = items[i];
              return SizedBox(
                width: 210,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () => _push(context, const GalleryScreen()),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    NetImage(src: g.image, height: 105, width: double.infinity),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _location(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(AppConfig.sanggarName, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(AppConfig.sanggarAddress, style: TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => openUrl(context, AppConfig.mapsUrl),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Buka Maps'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => openUrl(context, waUrl()),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('WhatsApp'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
