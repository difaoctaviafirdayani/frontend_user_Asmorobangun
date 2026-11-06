import '../core/api.dart';
import '../models/models.dart';

class GalleryRepository {
  final ApiClient _api;
  GalleryRepository(this._api);

  Future<List<GalleryItem>> fetchGallery() async {
    final res = await _api.get('/gallery');
    return mapList(res['gallery'], GalleryItem.fromJson);
  }
}
