import '../core/api.dart';
import '../core/validators.dart';
import '../repositories/forum_repository.dart';
import 'base_viewmodel.dart';

class NewThreadViewModel extends BaseViewModel {
  final ForumRepository _repo;
  NewThreadViewModel(this._repo);

  List<String> _categories = ForumRepository.defaultCategories;
  String _selected = ForumRepository.defaultCategories.first;
  bool _busy = false;
  String? _error;

  List<String> get categories => _categories;
  String get selectedCategory => _selected;
  bool get busy => _busy;

  String? get error => _error;

  Future<void> loadCategories() async {
    final cats = await _repo.fetchCategories();
    _categories = cats;
    if (!cats.contains(_selected)) _selected = cats.first;
    notifyListeners();
  }

  void selectCategory(String value) {
    _selected = value;
    notifyListeners();
  }

  Future<bool> submit({required String title, required String content}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.createThread(
        title: Validators.clean(title),
        content: Validators.clean(content),
        category: _selected,
      );
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
