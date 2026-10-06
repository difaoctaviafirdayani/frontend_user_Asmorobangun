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
  /// Pindah tab dari shell: 1 = Fasilitas, 2 = Forum, 4 = Akun.
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  static const double _pad = 20;

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _header(context),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_pad, 16, _pad, 0),
              child: NetImage(
                src: 'sanggar-utama.jpg',
                height: 220,
                width: double.infinity,
                radius: BorderRadius.circular(20),
              ),
            ),
            _SectionTitle('Pengumuman', actionLabel: 'Lihat semua', onAction: () => _push(context, const AnnouncementsScreen())),
            _announcements(context),
            _SectionTitle('Berita dan Artikel', actionLabel: 'Lihat semua', onAction: () => _push(context, const ArticlesScreen())),
            _featuredArticle(context),
            _SectionTitle('Layanan Sanggar', actionLabel: 'Lihat semua', onAction: () => onNavigate(1)),
            _facilities(context),
            _SectionTitle('Galeri Sanggar', actionLabel: 'Lihat semua', onAction: () => _push(context, const GalleryScreen())),
            _gallery(context),
            const _SectionTitle('Lokasi Kami'),
            _location(context),
            _SectionTitle('Forum Diskusi', actionLabel: 'Buka Forum', onAction: () => onNavigate(2)),
            _forum(),
          ]),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: AppColors.wood900,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_pad, 10, _pad, 16),
          child: Column(children: [
            Row(children: [
              Text('asmorobangun', style: logoStyle(size: 30)),
              const Spacer(),
              IconButton(
                tooltip: 'Akun',
                icon: const Icon(Icons.person_outline_rounded, color: AppColors.cream100, size: 28),
                onPressed: () => onNavigate(4),
              ),
            ]),
            const SizedBox(height: 6),
            Material(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _push(context, const SearchScreen()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text('Telusuri lebih lanjut', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _announcements(BuildContext context) {
    return AsyncView<List<Announcement>>(
      loader: () async => mapList((await api.get('/announcements'))['announcements'], Announcement.fromJson),
      builder: (context, items, _) {
        if (items.isEmpty) return const EmptyState('Belum ada pengumuman.');
        final shown = items.length > 8 ? 8 : items.length;
        return SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _pad),
            itemCount: shown,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final a = items[i];
              return SizedBox(
                width: 300,
                child: _CreamCard(
                  padding: EdgeInsets.zero,
                  onTap: () => _push(context, AnnouncementDetailScreen(item: a)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    NetImage(src: a.image ?? 'sanggar-tari.jpg', height: 130, width: double.infinity),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _BrownChip(a.type),
                        const SizedBox(height: 8),
                        Text(a.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.wood700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(formatDateLong(a.date), style: const TextStyle(color: AppColors.wood700, fontSize: 13)),
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
          padding: const EdgeInsets.symmetric(horizontal: _pad),
          child: _CreamCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _push(context, ArticleDetailScreen(slug: a.slug)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _BrownChip(a.category),
              const SizedBox(height: 10),
              Text(a.title, style: headingStyle(size: 20)),
              const SizedBox(height: 6),
              Text(a.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.wood700, fontSize: 14, height: 1.45)),
            ]),
          ),
        );
      },
    );
  }

  Widget _facilities(BuildContext context) {
    return AsyncView<List<Facility>>(
      loader: () async => mapList((await api.get('/facilities'))['facilities'], Facility.fromJson),
      builder: (context, items, _) {
        if (items.isEmpty) return const EmptyState('Belum ada layanan.');
        final shown = items.take(2).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pad),
          child: Column(children: [
            for (final f in shown) _FacilityRow(facility: f, onTap: () => _push(context, FacilityDetailScreen(id: f.id))),
          ]),
        );
      },
    );
  }

  Widget _gallery(BuildContext context) {
    return AsyncView<List<GalleryItem>>(
      loader: () async => mapList((await api.get('/gallery'))['gallery'], GalleryItem.fromJson),
      builder: (context, items, _) {
        if (items.isEmpty) return const EmptyState('Belum ada foto galeri.');
        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _pad),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _push(context, const GalleryScreen()),
              child: NetImage(
                src: items[i].image,
                width: 300,
                height: 210,
                radius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _location(BuildContext context) {
    const underline = TextStyle(decoration: TextDecoration.underline, fontSize: 13.5, fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: _CreamCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppConfig.sanggarName, style: headingStyle(size: 22)),
          const SizedBox(height: 4),
          const Text(AppConfig.sanggarAddress, style: TextStyle(color: AppColors.wood700, fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => openUrl(context, AppConfig.mapsUrl),
            child: NetImage(src: 'peta-lokasi.jpg', height: 150, width: double.infinity, radius: BorderRadius.circular(18)),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.wood700,
                  side: const BorderSide(color: AppColors.wood700, width: 1.3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: () => openUrl(context, AppConfig.mapsUrl),
                child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Buka di Google Maps', style: underline)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wood700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: () => openUrl(context, waUrl()),
                child: const FittedBox(fit: BoxFit.scaleDown, child: Text('WhatsApp Admin', style: underline)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _forum() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: _CreamCard(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          const Text(
            'Punya pertanyaan atau ingin berbagi pengalaman tentang Sanggar Asmorobangun? Gabunglah di forum diskusi kami!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.wood700, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wood700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigate(2),
              child: const Text('Masuk ke Forum', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(HomeScreen._pad, 22, HomeScreen._pad, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: headingStyle(size: 26))),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(actionLabel!, style: const TextStyle(color: AppColors.wood700, fontSize: 14.5)),
              ),
            ),
        ]),
      );
}

class _CreamCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const _CreamCard({required this.child, required this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.cream100,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class _BrownChip extends StatelessWidget {
  final String text;
  const _BrownChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: AppColors.wood700, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

class _FacilityRow extends StatelessWidget {
  final Facility facility;
  final VoidCallback onTap;
  const _FacilityRow({required this.facility, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = facility;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.wood700, width: 1))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetImage(src: f.image, width: 116, height: 86, radius: BorderRadius.circular(8)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(f.name.replaceAll(RegExp(r'\s*\(.*\)'), ''),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: headingStyle(size: 17)),
                ),
                if (f.avgRating != null) ...[
                  const Icon(Icons.star_rounded, color: AppColors.gold400, size: 20),
                  const SizedBox(width: 2),
                  Text(f.avgRating!.toStringAsFixed(1), style: const TextStyle(color: AppColors.wood700, fontSize: 13)),
                ],
              ]),
              const SizedBox(height: 4),
              Text(f.shortDesc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.wood700, fontSize: 13, height: 1.35)),
            ]),
          ),
        ]),
      ),
    );
  }
}