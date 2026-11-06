import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/validators.dart';
import 'base_viewmodel.dart';

class RegisterViewModel extends BaseViewModel {
  final AuthState _auth;
  RegisterViewModel(this._auth);

  bool _busy = false;
  String? _error;
  String? _emailServerError;

  bool get busy => _busy;

  String? get error => _error;

  String? get emailServerError => _emailServerError;

  void clearEmailServerError() => _emailServerError = null;

  void clearErrors() {
    _error = null;
    _emailServerError = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    _emailServerError = null;
    notifyListeners();
    try {
      await _auth.register(
        name: Validators.clean(name),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone.replaceAll(RegExp(r'[\s\-]'), ''),
      );
      return true;
    } on ApiException catch (e) {
      if (e.status == 409) {
        _emailServerError = e.message;
      } else {
        _error = e.message;
      }
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
