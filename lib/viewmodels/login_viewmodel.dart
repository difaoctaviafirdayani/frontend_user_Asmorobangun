import '../core/api.dart';
import '../core/auth_state.dart';
import 'base_viewmodel.dart';

class LoginViewModel extends BaseViewModel {
  final AuthState _auth;
  LoginViewModel(this._auth);

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> submit(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(email.trim().toLowerCase(), password);
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
