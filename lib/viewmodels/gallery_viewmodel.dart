import '../models/models.dart';
import '../repositories/gallery_repository.dart';
import 'base_viewmodel.dart';

class GalleryViewModel extends LoadableViewModel<List<GalleryItem>> {
  final GalleryRepository _repo;
  GalleryViewModel(this._repo);

  @override
  Future<List<GalleryItem>> fetch() => _repo.fetchGallery();
}
