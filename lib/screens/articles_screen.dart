import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

const _cardFill = Color(0xFFFDFBE8);
const _baseCategories = ['Sejarah', 'Budaya', 'Acara'];

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _search = TextEditingController();
  String _category = '';
  String _query = '';
  late Future<List<Article>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Article>> _load() async =>
      mapList((await api.get('/articles'))['articles'], Article.fromJson);

  void _refresh() => setState(() => _future = _load());

  void _openDetail(Article a) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug)));

  DateTime _dateOf(Article a) => DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);

  List<String> _categoriesOf(List<Article> all) {
    final extra = <String>[];
    for (final a in all) {
      final c = a.category.trim();
      if (c.isEmpty) continue;
      final known = [..._baseCategories, ...extra].any((e) => e.toLowerCase() == c.toLowerCase());
      if (!known) extra.add(c);
    }
    return [..._baseCategories, ...extra];
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Berita dan Artikel',
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snap) {
          final all = snap.data ?? const <Article>[];
          final loading = snap.connectionState != ConnectionState.done;

          final q = _query.trim().toLowerCase();
          final filtered = all.where((a) {
            final okCat = _category.isEmpty || a.category.toLowerCase() == _category.toLowerCase();
            final okQuery = q.isEmpty || a.title.toLowerCase().contains(q);
            return okCat && okQuery;
          }).toList()
            ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

          final showFeatured = q.isEmpty && _category.isEmpty && filtered.isNotEmpty;
          Article? featured;
          if (showFeatured) {
            featured = filtered.first;
          }
          final list = showFeatured ? filtered.where((a) => a.id != featured!.id).toList() : filtered;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _searchBar(),
              const SizedBox(height: 14),
              _dropdown(_categoriesOf(all)),
              const SizedBox(height: 18),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: AppColors.gold400)),
                )
              else if (snap.hasError)
                SizedBox(height: 300, child: ErrorView(message: snap.error.toString(), onRetry: _refresh))
              else if (filtered.isEmpty)
                const SizedBox(height: 300, child: EmptyState('Tidak ada artikel yang cocok.', icon: Icons.article_outlined))
              else ...[
                if (featured != null) ...[
                  _featuredCard(featured),
                  const SizedBox(height: 20),
                ],
                if (list.isNotEmpty) ...[
                  Text('Semua Artikel', style: headingStyle(size: 20, color: AppColors.wood700)),
                  const SizedBox(height: 10),
                  for (final a in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: _listCard(a)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar() => TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Cari berita atau artikel',
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
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

  Widget _dropdown(List<String> cats) {
    final items = ['', ...cats];
    final value = items.contains(_category) ? _category : '';
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
          onChanged: (v) => setState(() => _category = v ?? ''),
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
    return AppScaffold(
      title: 'Berita dan Artikel',
      backgroundColor: Colors.white,
      body: AsyncView<Article>(
        loader: () async => Article.fromJson(
            (await api.get('/articles/${Uri.encodeComponent(slug)}'))['article'] as Map<String, dynamic>),
        builder: (context, a, _) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: [
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
        ]),
      ),
    );
  }
}