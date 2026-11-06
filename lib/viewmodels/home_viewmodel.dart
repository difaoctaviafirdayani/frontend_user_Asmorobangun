import '../models/models.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/article_repository.dart';
import '../repositories/facility_repository.dart';
import '../repositories/gallery_repository.dart';
import 'base_viewmodel.dart';

class SectionState<T> {
  final LoadStatus status;
  final T? data;
  final String? error;
  const SectionState._(this.status, this.data, this.error);
  const SectionState.loading() : this._(LoadStatus.loading, null, null);
  const SectionState.success(T data) : this._(LoadStatus.success, data, null);
  const SectionState.failure(String error) : this._(LoadStatus.error, null, error);
}

class HomeViewModel extends BaseViewModel {
  final AnnouncementRepository _announcementRepo;
  final ArticleRepository _articleRepo;
  final FacilityRepository _facilityRepo;
  final GalleryRepository _galleryRepo;
  HomeViewModel(this._announcementRepo, this._articleRepo, this._facilityRepo, this._galleryRepo);

  SectionState<List<Announcement>> _announcements = const SectionState.loading();
  SectionState<Article?> _featured = const SectionState.loading();
  SectionState<List<Facility>> _facilities = const SectionState.loading();
  SectionState<List<GalleryItem>> _gallery = const SectionState.loading();

  SectionState<List<Announcement>> get announcements => _announcements;
  SectionState<Article?> get featuredArticle => _featured;
  SectionState<List<Facility>> get facilities => _facilities;
  SectionState<List<GalleryItem>> get gallery => _gallery;

  Future<void> loadAll() => Future.wait([
        loadAnnouncements(),
        loadFeaturedArticle(),
        loadFacilities(),
        loadGallery(),
      ]);

  Future<void> loadAnnouncements() =>
      _load(_announcementRepo.fetchAnnouncements, (s) => _announcements = s);

  Future<void> loadFeaturedArticle() => _load(_articleRepo.fetchFeatured, (s) => _featured = s);

  Future<void> loadFacilities() => _load(_facilityRepo.fetchFacilities, (s) => _facilities = s);

  Future<void> loadGallery() => _load(_galleryRepo.fetchGallery, (s) => _gallery = s);

  Future<void> _load<T>(Future<T> Function() fetch, void Function(SectionState<T>) assign) async {
    assign(SectionState<T>.loading());
    notifyListeners();
    try {
      assign(SectionState<T>.success(await fetch()));
    } catch (e) {
      assign(SectionState<T>.failure(e.toString()));
    }
    notifyListeners();
  }
}
