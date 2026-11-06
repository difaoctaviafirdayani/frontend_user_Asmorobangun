import '../models/models.dart';
import '../repositories/topeng_repository.dart';
import 'base_viewmodel.dart';

class TopengListViewModel extends LoadableViewModel<List<Topeng>> {
  final TopengRepository _repo;
  TopengListViewModel(this._repo);

  @override
  Future<List<Topeng>> fetch() => _repo.fetchTopengList();
}
