import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/article_repository.dart';
import '../repositories/facility_repository.dart';
import '../repositories/forum_repository.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/topeng_repository.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/common.dart';
import 'announcements_screen.dart';
import 'articles_screen.dart';
import 'facilities_screen.dart';
import 'forum_screen.dart';
import 'gallery_screen.dart';
import 'topeng_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => SearchViewModel(
        c.read<ArticleRepository>(),
        c.read<AnnouncementRepository>(),
        c.read<FacilityRepository>(),
        c.read<TopengRepository>(),
        c.read<ForumRepository>(),
        c.read<GalleryRepository>(),
      )..load(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _open(SearchHit h) {
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _header(context, vm),
        Expanded(child: vm.hasQuery ? _results(vm) : _features()),
      ]),
    );
  }

  Widget _header(BuildContext context, SearchViewModel vm) {
    return Container(
      width: double.infinity,
      color: AppColors.wood900,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('asmorobangun', style: logoStyle(size: 30, color: AppColors.cream100)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: vm.setQuery,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Telusuri lebih lanjut',
            hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
            suffixIcon: vm.query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      _controller.clear();
                      vm.setQuery('');
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

  Widget _results(SearchViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
    }
    final hits = vm.results;
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