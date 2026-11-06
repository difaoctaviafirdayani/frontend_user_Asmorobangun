import '../models/models.dart';
import '../repositories/article_repository.dart';
import 'base_viewmodel.dart';

class ArticleListViewModel extends BaseViewModel {
  final ArticleRepository _repo;
  ArticleListViewModel(this._repo);

  static const baseCategories = ['Sejarah', 'Budaya', 'Acara'];

  List<Article> _all = const [];
  List<Article> _filtered = const [];
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  String _query = '';
  String _category = '';

  LoadStatus get status => _status;
  String? get error => _error;
  String get query => _query;
  String get category => _category;

  List<Article> get filtered => _filtered;

  List<String> get categories {
    final extra = <String>[];
    for (final a in _all) {
      final c = a.category.trim();
      if (c.isEmpty) continue;
      final known = [...baseCategories, ...extra].any((e) => e.toLowerCase() == c.toLowerCase());
      if (!known) extra.add(c);
    }
    return [...baseCategories, ...extra];
  }

  Article? get featured {
    final plain = _query.trim().isEmpty && _category.isEmpty;
    return plain && _filtered.isNotEmpty ? _filtered.first : null;
  }

  List<Article> get others {
    final f = featured;
    return f == null ? _filtered : _filtered.where((a) => a.id != f.id).toList();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.fetchArticles();
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    _applyFilter();
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    _applyFilter();
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _filtered = _all.where((a) {
      final okCat = _category.isEmpty || a.category.toLowerCase() == _category.toLowerCase();
      final okQuery = q.isEmpty || a.title.toLowerCase().contains(q);
      return okCat && okQuery;
    }).toList()
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
  }

  DateTime _dateOf(Article a) => DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
