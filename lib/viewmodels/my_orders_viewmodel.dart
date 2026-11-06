import '../models/models.dart';
import '../repositories/facility_repository.dart';
import '../repositories/topeng_repository.dart';
import 'base_viewmodel.dart';

class TopengOrdersViewModel extends LoadableViewModel<List<TopengOrder>> {
  final TopengRepository _repo;
  TopengOrdersViewModel(this._repo);

  @override
  Future<List<TopengOrder>> fetch() => _repo.fetchMyOrders();

  String reviewPath(TopengOrder o) => TopengRepository.reviewPath(o.id);
}

class BookingsViewModel extends LoadableViewModel<List<Booking>> {
  final FacilityRepository _repo;
  BookingsViewModel(this._repo);

  @override
  Future<List<Booking>> fetch() => _repo.fetchMyBookings();

  String reviewPath(Booking b) => FacilityRepository.reviewPath(b.id);
}
