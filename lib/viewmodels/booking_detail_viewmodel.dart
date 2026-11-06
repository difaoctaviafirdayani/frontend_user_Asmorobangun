import '../models/models.dart';
import '../repositories/facility_repository.dart';
import 'base_viewmodel.dart';

class BookingDetailViewModel extends LoadableViewModel<Facility?> {
  final FacilityRepository _repo;
  final Booking booking;
  BookingDetailViewModel(this._repo, this.booking);

  @override
  Future<Facility?> fetch() async {
    if (booking.status != 'menunggu_pembayaran') return null;
    return (await _repo.fetchFacility(booking.facilityId)).facility;
  }
}
