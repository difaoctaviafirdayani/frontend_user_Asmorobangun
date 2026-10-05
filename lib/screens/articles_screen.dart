import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _category = '';
  String _query = '';
  late Future<List<Article>> _future = _load();
  late final Future<List<String>> _categories = _loadCategories();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<List<Article>> _load() async {
    final q = <String, String>{if (_query.isNotEmpty) 'q': _query, if (_category.isNotEmpty) 'category': _category};
    return mapList((await api.get('/articles', query: q))['articles'], Article.fromJson);
  }

  Future<List<String>> _loadCategories() async {
    final res = await api.get('/articles/categories');
    final list = res['categories'];
    return list is List ? list.map((e) => e.toString()).toList() : <String>[];
  }

  void _refresh() => setState(() => _future = _load());

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = v.trim();
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Artikel & Berita',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: inputDec('Cari artikel').copyWith(prefixIcon: const Icon(Icons.search_rounded)),
          ),
        ),
        FutureBuilder<List<String>>(
          future: _categories,
          builder: (context, snap) {
            final cats = snap.data ?? const <String>[];
            if (cats.isEmpty) return const SizedBox(height: 6);
            return SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  for (final c in ['', ...cats])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.isEmpty ? 'Semua' : c),
                        selected: _category == c,
                        selectedColor: AppColors.gold300,
                        onSelected: (_) {
                          _category = c;
                          _refresh();
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: FutureBuilder<List<Article>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
              }
              if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
              final items = snap.data ?? [];
              if (items.isEmpty) return const EmptyState('Tidak ada artikel yang cocok.', icon: Icons.article_outlined);
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = items[i];
                  return AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NetImage(src: a.image, height: 140, width: double.infinity),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            TagChip(a.category, gold: true),
                            const SizedBox(width: 8),
                            Text(formatDate(a.date), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ]),
                          const SizedBox(height: 8),
                          Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(a.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                        ]),
                      ),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Artikel',
      body: AsyncView<Article>(
        // slug berasal dari server/pencarian, tetap di-encode agar aman dipakai di URL.
        loader: () async => Article.fromJson((await api.get('/articles/${Uri.encodeComponent(slug)}'))['article'] as Map<String, dynamic>),
        builder: (context, a, _) => ListView(padding: const EdgeInsets.all(16), children: [
          NetImage(src: a.image, height: 200, width: double.infinity, radius: BorderRadius.circular(16)),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: TagChip(a.category, gold: true)),
          const SizedBox(height: 8),
          Text(a.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.wood900, height: 1.25)),
          const SizedBox(height: 6),
          Text('${a.author} · ${formatDate(a.date)}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
          const SizedBox(height: 16),
          for (final para in a.content.split(RegExp(r'\n\s*\n')))
            if (para.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(para.trim(), style: const TextStyle(height: 1.6, fontSize: 15)),
              ),
        ]),
      ),
    );
  }
}
