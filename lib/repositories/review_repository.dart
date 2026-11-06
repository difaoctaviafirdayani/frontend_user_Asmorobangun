import '../core/api.dart';

class ReviewRepository {
  final ApiClient _api;
  ReviewRepository(this._api);

  Future<void> save(String basePath, {required int rating, required String comment, required bool editing}) async {
    final body = {'rating': rating, 'comment': comment};
    if (editing) {
      await _api.put(basePath, body: body);
    } else {
      await _api.post(basePath, body: body);
    }
  }

  Future<void> uploadImage(String basePath, List<int> bytes, String filename) async {
    await _api.upload('$basePath/image', field: 'image', bytes: bytes, filename: filename);
  }

  Future<void> deleteImage(String basePath) async {
    await _api.delete('$basePath/image');
  }

  Future<void> delete(String basePath) async {
    await _api.delete(basePath);
  }
}
