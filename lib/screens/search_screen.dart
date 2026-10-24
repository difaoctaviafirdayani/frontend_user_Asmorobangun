import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'announcements_screen.dart';
import 'articles_screen.dart';
import 'facilities_screen.dart';
import 'forum_screen.dart';
import 'gallery_screen.dart';
import 'topeng_screen.dart';

Widget searchAction(BuildContext context) => IconButton(
      tooltip: 'Cari',
      icon: const Icon(Icons.search_rounded),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
    );

class _Hit {
  final String id, title, type;
  final String? slug;
  const _Hit(this.id, this.title, this.type, [this.slug]);
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  late final Future<List<_Hit>> _index = _buildIndex();

  Future<List<T>> _safe<T>(Future<List<T>> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return <T>[];
    }
  }

  Future<List<_Hit>> _buildIndex() async {
    final r = await Future.wait([
      _safe(() async => mapList((await api.get('/articles'))['articles'], Article.fromJson)),
      _safe(() async => mapList((await api.get('/announcements'))['announcements'], Announcement.fromJson)),
      _safe(() async => mapList((await api.get('/facilities'))['facilities'], Facility.fromJson)),
      _safe(() async => mapList((await api.get('/topeng'))['topeng'], Topeng.fromJson)),
      _safe(() async => mapList((await api.get('/forum'))['threads'], ThreadSummary.fromJson)),
      _safe(() async => mapList((await api.get('/gallery'))['gallery'], GalleryItem.fromJson)),
    ]);
    return [
      for (final a in r[0] as List<Article>) _Hit(a.id, a.title, 'Artikel', a.slug),
      for (final a in r[1] as List<Announcement>) _Hit(a.id, a.title, 'Pengumuman'),
      for (final f in r[2] as List<Facility>) _Hit(f.id, f.name, 'Layanan'),
      for (final t in r[3] as List<Topeng>) _Hit(t.id, t.name, 'Topeng'),
      for (final t in r[4] as List<ThreadSummary>) _Hit(t.id, t.title, 'Forum'),
      for (final g in r[5] as List<GalleryItem>) _Hit(g.id, g.title, 'Galeri'),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _open(_Hit h) {
    switch (h.type) {
      case 'Artikel':
        _push(ArticleDetailScreen(slug: h.slug ?? h.id));
      case 'Pengumuman':
        _push(const AnnouncementsScreen());
      case 'Layanan':
        _push(FacilityDetailScreen(id: h.id));
      case 'Topeng':
        _push(TopengDetailScreen(id: h.id));
      case 'Forum':
        _push(ThreadScreen(id: h.id));
      case 'Galeri':
        _push(const GalleryScreen());
    }
  }

  List<_Hit> _filter(List<_Hit> all) {
    final words = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];
    return all.where((h) {
      final t = h.title.toLowerCase();
      return words.every(t.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _query.trim().isEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _header(context),
        Expanded(child: empty ? _features() : _results()),
      ]),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.wood900,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('asmorobangun', style: logoStyle(size: 30, color: AppColors.cream100)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Telusuri lebih lanjut',
            hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: Colors.white.withAlpha(60),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ]),
    );
  }

  Widget _results() {
    return FutureBuilder<List<_Hit>>(
      future: _index,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
        }
        final hits = _filter(snap.data ?? const <_Hit>[]);
        if (hits.isEmpty) return const EmptyState('Tidak ada hasil.', icon: Icons.search_off_rounded);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: hits.length,
          itemBuilder: (context, i) {
            final h = hits[i];
            return InkWell(
              onTap: () => _open(h),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.wood700, width: 1)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.type.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.wood700)),
                      const SizedBox(height: 2),
                      Text(h.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.3, color: AppColors.wood700)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.wood700),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _features() {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.newspaper_outlined, 'Artikel & Berita', () => _push(const ArticlesScreen())),
      (Icons.campaign_outlined, 'Pengumuman', () => _push(const AnnouncementsScreen())),
      (Icons.image_outlined, 'Galeri Sanggar', () => _push(const GalleryScreen())),
      (Icons.calendar_today_outlined, 'Layanan Sanggar', () => _push(const FacilitiesScreen())),
      (Icons.theater_comedy_outlined, 'Beli Topeng', () => _push(const TopengScreen())),
      (Icons.forum_outlined, 'Forum Diskusi', () => _push(const ForumScreen())),
      (Icons.shopping_cart_outlined, 'Pesanan Saya', () => Navigator.pushNamed(context, Routes.myOrders)),
    ];
    final itemW = (MediaQuery.sizeOf(context).width - 40) / 4;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 24), children: [
      Text('Jelajahi Fitur', style: headingStyle(size: 26, color: AppColors.wood700)),
      const SizedBox(height: 20),
      Wrap(runSpacing: 22, children: [
        for (final it in items)
          SizedBox(
            width: itemW,
            child: GestureDetector(
              onTap: it.$3,
              child: Column(children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.cream300,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.wood700, width: 1.4),
                  ),
                  child: Icon(it.$1, size: 30, color: AppColors.wood700),
                ),
                const SizedBox(height: 8),
                Text(it.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.25, color: AppColors.wood700)),
              ]),
            ),
          ),
      ]),
    ]);
  }
}