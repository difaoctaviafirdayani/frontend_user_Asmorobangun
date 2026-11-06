import '../core/api.dart';
import '../core/auth_state.dart';
import 'base_viewmodel.dart';

class ForgotPasswordViewModel extends BaseViewModel {
  final AuthState _auth;
  ForgotPasswordViewModel(this._auth);

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;

  Future<String?> submit({
    required String email,
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_busy) return null;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await _auth.resetPassword(
        email: email.trim(),
        phone: phone.trim(),
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Terjadi kesalahan. Coba lagi.';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
