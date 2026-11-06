import '../models/models.dart';
import '../repositories/facility_repository.dart';
import 'base_viewmodel.dart';

class FacilityListViewModel extends LoadableViewModel<List<Facility>> {
  final FacilityRepository _repo;
  FacilityListViewModel(this._repo);

  @override
  Future<List<Facility>> fetch() => _repo.fetchFacilities();
}
