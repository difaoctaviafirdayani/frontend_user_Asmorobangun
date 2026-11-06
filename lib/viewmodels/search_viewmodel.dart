import '../models/models.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/article_repository.dart';
import '../repositories/facility_repository.dart';
import '../repositories/forum_repository.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/topeng_repository.dart';
import 'base_viewmodel.dart';

class SearchHit {
  final String id, title, type;
  final String? slug;
  const SearchHit(this.id, this.title, this.type, [this.slug]);
}

class SearchViewModel extends BaseViewModel {
  final ArticleRepository _articles;
  final AnnouncementRepository _announcements;
  final FacilityRepository _facilities;
  final TopengRepository _topeng;
  final ForumRepository _forum;
  final GalleryRepository _gallery;
  SearchViewModel(this._articles, this._announcements, this._facilities, this._topeng, this._forum, this._gallery);

  List<SearchHit> _index = const [];
  List<SearchHit> _results = const [];
  bool _loading = true;
  String _query = '';

  bool get isLoading => _loading;
  String get query => _query;
  bool get hasQuery => _query.trim().isNotEmpty;
  List<SearchHit> get results => _results;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final r = await Future.wait([
      _safe(_articles.fetchArticles),
      _safe(_announcements.fetchAnnouncements),
      _safe(_facilities.fetchFacilities),
      _safe(_topeng.fetchTopengList),
      _safe(_forum.fetchThreads),
      _safe(_gallery.fetchGallery),
    ]);
    _index = [
      for (final a in r[0] as List<Article>) SearchHit(a.id, a.title, 'Artikel', a.slug),
      for (final a in r[1] as List<Announcement>) SearchHit(a.id, a.title, 'Pengumuman'),
      for (final f in r[2] as List<Facility>) SearchHit(f.id, f.name, 'Layanan'),
      for (final t in r[3] as List<Topeng>) SearchHit(t.id, t.name, 'Topeng'),
      for (final t in r[4] as List<ThreadSummary>) SearchHit(t.id, t.title, 'Forum'),
      for (final g in r[5] as List<GalleryItem>) SearchHit(g.id, g.title, 'Galeri'),
    ];
    _loading = false;
    _applyFilter();
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    _applyFilter();
    notifyListeners();
  }

  Future<List<T>> _safe<T>(Future<List<T>> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return <T>[];
    }
  }

  void _applyFilter() {
    final words = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      _results = const [];
      return;
    }
    _results = _index.where((h) {
      final t = h.title.toLowerCase();
      return words.every(t.contains);
    }).toList();
  }
}
