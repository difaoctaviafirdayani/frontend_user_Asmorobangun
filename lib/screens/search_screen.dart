import 'dart:async';

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

/// Tombol cari yang dipasang di app bar tiap tab.
Widget searchAction(BuildContext context) => IconButton(
      tooltip: 'Cari',
      icon: const Icon(Icons.search_rounded),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
    );

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<SearchHit> _hits = [];
  bool _loading = false;
  String? _error;
  int _token = 0; // supaya jawaban lama tidak menimpa pencarian terbaru

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      setState(() {
        _hits = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final my = ++_token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await api.get('/search', query: {'q': q});
      if (my != _token || !mounted) return;
      setState(() {
        _hits = [
          ...mapList(res['articles'], SearchHit.fromJson),
          ...mapList(res['facilities'], SearchHit.fromJson),
          ...mapList(res['topeng'], SearchHit.fromJson),
          ...mapList(res['forum'], SearchHit.fromJson),
        ];
        _loading = false;
      });
    } on ApiException catch (e) {
      if (my == _token && mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  void _open(SearchHit h) {
    Widget? page;
    switch (h.type) {
      case 'Artikel':
        page = ArticleDetailScreen(slug: h.slug ?? h.id);
      case 'Fasilitas':
        page = FacilityDetailScreen(id: h.id);
      case 'Topeng':
        page = TopengDetailScreen(id: h.id);
      case 'Forum':
        page = ThreadScreen(id: h.id);
    }
    if (page != null) {
      final p = page;
      Navigator.push(context, MaterialPageRoute(builder: (_) => p));
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = _controller.text.trim().isEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.wood900,
        foregroundColor: AppColors.cream100,
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: AppColors.cream100),
          cursorColor: AppColors.gold300,
          decoration: const InputDecoration(
            hintText: 'Cari Fitur yang Kamu Inginkan',
            hintStyle: TextStyle(color: AppColors.gold300),
            border: InputBorder.none,
          ),
        ),
      ),
      body: empty ? _quickLinks() : _results(),
    );
  }

  Widget _results() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
    if (_error != null) return EmptyState(_error!, icon: Icons.cloud_off_outlined);
    if (_hits.isEmpty) return const EmptyState('Tidak ada hasil.', icon: Icons.search_off_rounded);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _hits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final h = _hits[i];
        return AppCard(
          onTap: () => _open(h),
          child: Row(children: [
            Expanded(child: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            TagChip(h.type),
          ]),
        );
      },
    );
  }

  Widget _quickLinks() {
    // Tiap item membuka halaman lewat Navigator. 'Pesanan Saya' memakai rute
    // bernama sehingga melewati penjaga rute (harus login).
    final items = <(IconData, String, VoidCallback)>[
      (Icons.article_outlined, 'Artikel & Berita', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticlesScreen()))),
      (Icons.campaign_outlined, 'Pengumuman', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()))),
      (Icons.photo_library_outlined, 'Galeri Sanggar', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()))),
      (Icons.receipt_long_outlined, 'Pesanan Saya', () => Navigator.pushNamed(context, Routes.myOrders)),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Jelajahi fitur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 10),
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: it.$3,
            child: Row(children: [
              Icon(it.$1, color: AppColors.wood700),
              const SizedBox(width: 12),
              Expanded(child: Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ]),
          ),
        ),
    ]);
  }
}
