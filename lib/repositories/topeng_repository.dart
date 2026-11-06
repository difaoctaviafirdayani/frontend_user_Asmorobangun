import '../core/api.dart';
import '../models/models.dart';

class TopengDetail {
  final Topeng topeng;
  final List<Review> reviews;
  TopengDetail(this.topeng, this.reviews);
}

class TopengRepository {
  final ApiClient _api;
  TopengRepository(this._api);

  Future<List<Topeng>> fetchTopengList() async {
    final res = await _api.get('/topeng');
    return mapList(res['topeng'], Topeng.fromJson);
  }

  Future<TopengDetail> fetchTopeng(String id) async {
    final res = await _api.get('/topeng/${Uri.encodeComponent(id)}');
    return TopengDetail(
      Topeng.fromJson(res['topeng'] as Map<String, dynamic>),
      mapList(res['reviews'], Review.fromJson),
    );
  }

  Future<TopengOrder> createOrder({
    required String topengId,
    required int qty,
    required String buyerPhone,
    required String message,
  }) async {
    final res = await _api.post('/topeng/${Uri.encodeComponent(topengId)}/order', body: {
      'qty': qty,
      'buyerPhone': buyerPhone,
      'message': message,
    });
    return TopengOrder.fromJson(res['order'] as Map<String, dynamic>);
  }

  Future<TopengOrder> fetchOrder(String orderId) async {
    final res = await _api.get('/topeng/orders/${Uri.encodeComponent(orderId)}');
    return TopengOrder.fromJson(res['order'] as Map<String, dynamic>);
  }

  Future<List<TopengOrder>> fetchMyOrders() async {
    final res = await _api.get('/topeng/orders/mine');
    return mapList(res['orders'], TopengOrder.fromJson);
  }

  static String reviewPath(String orderId) => '/topeng/orders/$orderId/review';

  Future<String> askAssistant(String message, List<Map<String, String>> history) async {
    final res = await _api.post('/ai/chat', body: {'message': message, 'history': history});
    return (res['reply'] ?? '').toString();
  }
}
