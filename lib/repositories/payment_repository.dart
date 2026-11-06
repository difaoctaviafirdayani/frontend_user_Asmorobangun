import '../core/api.dart';

class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  String _base(String kind, String id) =>
      kind == 'topeng' ? '/topeng/orders/$id' : '/bookings/$id';

  Future<Map<String, dynamic>> fetchInfo(String kind, String id, String method) =>
      _api.get('${_base(kind, id)}/${method == 'qris' ? 'qris' : 'transfer'}');

  Future<void> chooseCash(String kind, String id) async {
    await _api.post('${_base(kind, id)}/cash');
  }

  Future<void> uploadProof(String kind, String id, String method, List<int> bytes, String filename) async {
    await _api.upload('${_base(kind, id)}/proof',
        field: 'proof', bytes: bytes, filename: filename, fields: {'paymentMethod': method});
  }
}
