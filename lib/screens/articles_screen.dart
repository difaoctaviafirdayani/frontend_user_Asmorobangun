import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../repositories/article_repository.dart';
import '../viewmodels/article_detail_viewmodel.dart';
import '../viewmodels/article_list_viewmodel.dart';
import '../viewmodels/base_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/load_status_view.dart';

const _cardFill = Color(0xFFFDFBE8);

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ArticleListViewModel(c.read<ArticleRepository>())..load(),
      child: const _ArticlesView(),
    );
  }
}

class _ArticlesView extends StatefulWidget {
  const _ArticlesView();

  @override
  State<_ArticlesView> createState() => _ArticlesViewState();
}

class _ArticlesViewState extends State<_ArticlesView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDetail(Article a) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug)));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ArticleListViewModel>();
    return AppScaffold(
      title: 'Berita dan Artikel',
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _searchBar(vm),
          const SizedBox(height: 14),
          _dropdown(vm),
          const SizedBox(height: 18),
          ..._content(vm),
        ],
      ),
    );
  }

  List<Widget> _content(ArticleListViewModel vm) {
    switch (vm.status) {
      case LoadStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold400)),
          ),
        ];
      case LoadStatus.error:
        return [SizedBox(height: 300, child: ErrorView(message: vm.error ?? '', onRetry: vm.load))];
      case LoadStatus.success:
        if (vm.filtered.isEmpty) {
          return const [
            SizedBox(height: 300, child: EmptyState('Tidak ada artikel yang cocok.', icon: Icons.article_outlined)),
          ];
        }
        final featured = vm.featured;
        final list = vm.others;
        return [
          if (featured != null) ...[
            _featuredCard(featured),
            const SizedBox(height: 20),
          ],
          if (list.isNotEmpty) ...[
            Text('Semua Artikel', style: headingStyle(size: 20, color: AppColors.wood700)),
            const SizedBox(height: 10),
            for (final a in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: _listCard(a)),
          ],
        ];
    }
  }

  Widget _searchBar(ArticleListViewModel vm) => TextField(
        controller: _search,
        onChanged: vm.setQuery,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Cari berita atau artikel',
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
          suffixIcon: vm.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    _search.clear();
                    vm.setQuery('');
                  },
                ),
          filled: true,
          fillColor: AppColors.wood700,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );

  Widget _dropdown(ArticleListViewModel vm) {
    final items = ['', ...vm.categories];
    final value = items.contains(vm.category) ? vm.category : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wood700, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.wood700),
          style: const TextStyle(fontSize: 15, color: AppColors.wood700),
          items: [
            for (final c in items)
              DropdownMenuItem(
                value: c,
                child: Text(c.isEmpty ? 'Semua kategori' : c),
              ),
          ],
          onChanged: (v) => vm.setCategory(v ?? ''),
        ),
      ),
    );
  }

  Widget _darkTag(String text, {double size = 12}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: AppColors.wood700, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: size, color: Colors.white)),
      );

  Widget _featuredCard(Article a) {
    const r = BorderRadius.all(Radius.circular(24));
    return GestureDetector(
      onTap: () => _openDetail(a),
      child: Container(
        decoration: BoxDecoration(
          color: _cardFill,
          borderRadius: r,
          border: Border.all(color: AppColors.wood700, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(22.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            NetImage(src: a.image, height: 190, width: double.infinity),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _darkTag(a.category),
                const SizedBox(height: 8),
                Text(a.title, style: headingStyle(size: 20, color: AppColors.wood700)),
                const SizedBox(height: 6),
                Text(a.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.wood700, height: 1.35)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _listCard(Article a) {
    return GestureDetector(
      onTap: () => _openDetail(a),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _cardFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.wood700, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.5),
          child: Row(children: [
            NetImage(src: a.image, width: 125, height: double.infinity),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _darkTag(a.category),
                  const SizedBox(height: 6),
                  Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: headingStyle(size: 15, color: AppColors.wood700)),
                  const Spacer(),
                  Text(formatDateLong(a.date), style: const TextStyle(fontSize: 12.5, color: AppColors.wood700)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ArticleDetailViewModel(c.read<ArticleRepository>(), slug)..load(),
      child: const _ArticleDetailView(),
    );
  }
}

class _ArticleDetailView extends StatelessWidget {
  const _ArticleDetailView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ArticleDetailViewModel>();
    return AppScaffold(
      title: 'Berita dan Artikel',
      backgroundColor: Colors.white,
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (_) => _content(vm.article!),
      ),
    );
  }

  Widget _content(Article a) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: [
          NetImage(src: a.image, height: 220, width: double.infinity, radius: BorderRadius.circular(22)),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(color: AppColors.wood700, borderRadius: BorderRadius.circular(999)),
              child: Text(a.category, style: const TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          Text(a.title, style: headingStyle(size: 24, color: AppColors.wood700)),
          const SizedBox(height: 6),
          Text('Oleh ${a.author} - ${formatDateLong(a.date)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.wood700)),
          const SizedBox(height: 14),
          for (final para in a.content.split(RegExp(r'\n\s*\n')))
            if (para.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(para.trim(), style: const TextStyle(height: 1.55, fontSize: 15.5, color: AppColors.wood700)),
              ),
  ]);
}
