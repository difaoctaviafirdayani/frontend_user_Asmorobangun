import '../core/api.dart';
import '../models/models.dart';

class FacilityDetail {
  final Facility facility;
  final List<Review> reviews;
  FacilityDetail(this.facility, this.reviews);
}

class FacilityRepository {
  final ApiClient _api;
  FacilityRepository(this._api);

  Future<List<Facility>> fetchFacilities() async {
    final res = await _api.get('/facilities');
    return mapList(res['facilities'], Facility.fromJson);
  }

  Future<FacilityDetail> fetchFacility(String id) async {
    final res = await _api.get('/facilities/${Uri.encodeComponent(id)}');
    return FacilityDetail(
      Facility.fromJson(res['facility'] as Map<String, dynamic>),
      mapList(res['reviews'], Review.fromJson),
    );
  }

  Future<Booking> createBooking(Map<String, dynamic> body) async {
    final res = await _api.post('/bookings', body: body);
    return Booking.fromJson(res['booking'] as Map<String, dynamic>);
  }

  static String reviewPath(String bookingId) => '/bookings/$bookingId/review';

  Future<List<Booking>> fetchMyBookings() async {
    final res = await _api.get('/bookings/mine');
    return mapList(res['bookings'], Booking.fromJson);
  }
}
