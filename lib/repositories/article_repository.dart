import '../core/api.dart';
import '../models/models.dart';

class ArticleRepository {
  final ApiClient _api;
  ArticleRepository(this._api);

  Future<List<Article>> fetchArticles() async {
    final res = await _api.get('/articles');
    return mapList(res['articles'], Article.fromJson);
  }

  Future<Article?> fetchFeatured() async {
    final res = await _api.get('/articles', query: {'limit': '1'});
    final featured = res['featured'];
    return featured is Map<String, dynamic> ? Article.fromJson(featured) : null;
  }

  Future<Article> fetchArticle(String slug) async {
    final res = await _api.get('/articles/${Uri.encodeComponent(slug)}');
    return Article.fromJson(res['article'] as Map<String, dynamic>);
  }
}
