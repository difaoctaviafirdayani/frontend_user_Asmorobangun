import '../models/models.dart';
import '../repositories/article_repository.dart';
import 'base_viewmodel.dart';

class ArticleDetailViewModel extends BaseViewModel {
  final ArticleRepository _repo;
  final String slug;
  ArticleDetailViewModel(this._repo, this.slug);

  Article? _article;
  LoadStatus _status = LoadStatus.loading;
  String? _error;

  Article? get article => _article;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _article = await _repo.fetchArticle(slug);
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
