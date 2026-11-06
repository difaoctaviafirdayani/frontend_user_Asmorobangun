import '../models/models.dart';
import '../repositories/forum_repository.dart';
import 'base_viewmodel.dart';

class ForumListViewModel extends BaseViewModel {
  final ForumRepository _repo;
  ForumListViewModel(this._repo);

  static const filterCategories = ['Diskusi Umum', 'Layanan'];

  List<ThreadSummary> _all = const [];
  List<ThreadSummary> _filtered = const [];
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  String _query = '';
  String _category = '';

  LoadStatus get status => _status;
  String? get error => _error;
  String get query => _query;
  String get category => _category;
  List<ThreadSummary> get threads => _filtered;

  bool get isEmptyOnServer => _all.isEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.fetchThreads();
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
    _filtered = _all.where((t) {
      final okCat = _category.isEmpty || t.category.toLowerCase() == _category.toLowerCase();
      final okQ = q.isEmpty || t.title.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
  }
}
