import '../repositories/facility_repository.dart';
import 'base_viewmodel.dart';

class FacilityDetailViewModel extends LoadableViewModel<FacilityDetail> {
  final FacilityRepository _repo;
  final String id;
  FacilityDetailViewModel(this._repo, this.id);

  @override
  Future<FacilityDetail> fetch() => _repo.fetchFacility(id);
}
