import '../core/api.dart';
import '../models/models.dart';

class AnnouncementRepository {
  final ApiClient _api;
  AnnouncementRepository(this._api);

  Future<List<Announcement>> fetchAnnouncements() async {
    final res = await _api.get('/announcements');
    return mapList(res['announcements'], Announcement.fromJson);
  }
}
