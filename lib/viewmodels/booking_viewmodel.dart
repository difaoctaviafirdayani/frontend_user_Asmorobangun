import '../core/api.dart';
import '../core/format.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../repositories/facility_repository.dart';
import 'base_viewmodel.dart';

class BookingViewModel extends BaseViewModel {
  final FacilityRepository _repo;
  final Facility facility;
  BookingViewModel(this._repo, this.facility);

  bool _busy = false;
  String? _error;
  Booking? _result;

  bool get busy => _busy;
  String? get error => _error;

  Booking? get result => _result;

  Future<bool> submit({
    DateTime? date,
    String scheduleText = '',
    String notes = '',
    String eventType = '',
    String location = '',
    String guests = '',
    String qty = '1',
  }) async {
    final f = facility;
    final body = <String, dynamic>{
      'facilityId': f.id,
      'date': f.usesDatePicker ? dateParam(date!) : Validators.clean(scheduleText),
      'notes': Validators.clean(notes),
      'paymentMethod': f.needsPaymentNow ? 'qris' : null,
    };
    if (f.bookingType == 'event') {
      body['eventType'] = Validators.clean(eventType);
      body['location'] = Validators.clean(location);
      final g = int.tryParse(guests.trim());
      if (g != null) body['guestCount'] = g;
    }
    if (f.bookingType == 'wisata') body['guestCount'] = int.parse(qty.trim());

    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _result = await _repo.createBooking(body);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshResult() async {
    final current = _result;
    if (current == null) return;
    try {
      final mine = (await _repo.fetchMyBookings()).where((x) => x.id == current.id);
      if (mine.isNotEmpty) {
        _result = mine.first;
        notifyListeners();
      }
    } on ApiException {
      return;
    }
  }
}