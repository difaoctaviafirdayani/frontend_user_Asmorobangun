import '../models/models.dart';
import '../repositories/announcement_repository.dart';
import 'base_viewmodel.dart';

class AnnouncementViewModel extends LoadableViewModel<List<Announcement>> {
  final AnnouncementRepository _repo;
  AnnouncementViewModel(this._repo);

  @override
  Future<List<Announcement>> fetch() => _repo.fetchAnnouncements();
}
