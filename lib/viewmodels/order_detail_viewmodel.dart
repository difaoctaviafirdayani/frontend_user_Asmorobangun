import '../models/models.dart';
import '../repositories/topeng_repository.dart';
import 'base_viewmodel.dart';

class OrderDetailViewModel extends LoadableViewModel<TopengOrder> {
  final TopengRepository _repo;
  final String orderId;
  OrderDetailViewModel(this._repo, this.orderId);

  @override
  Future<TopengOrder> fetch() => _repo.fetchOrder(orderId);
}
