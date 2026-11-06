import '../core/api.dart';
import '../core/auth_state.dart';
import '../repositories/auth_repository.dart';
import 'base_viewmodel.dart';

class ProfileViewModel extends BaseViewModel {
  final AuthRepository _repo;
  final AuthState _auth;
  ProfileViewModel(this._repo, this._auth);

  static const maxAvatarBytes = 3 * 1024 * 1024;

  bool _busy = false;
  String? _error;

  bool get busy => _busy;

  String? get error => _error;

  Future<bool> changeAvatar(PickedImage file) async {
    if (file.bytes.length > maxAvatarBytes) {
      _error = 'Ukuran foto maksimal 3MB.';
      notifyListeners();
      return false;
    }
    return _run(() => _repo.uploadAvatar(file.bytes, file.name));
  }

  Future<bool> removeAvatar() => _run(_repo.deleteAvatar);

  Future<bool> _run(Future<Map<String, dynamic>> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final res = await action();
      await _auth.setUserFromResponse(res);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
