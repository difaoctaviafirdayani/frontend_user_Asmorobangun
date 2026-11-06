import '../core/api.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../repositories/topeng_repository.dart';
import 'base_viewmodel.dart';

class TopengDetailViewModel extends BaseViewModel {
  final TopengRepository _repo;
  final String id;
  TopengDetailViewModel(this._repo, this.id);

  static const countryCodes = <(String, String)>[
    ('62', 'Indonesia'),
    ('60', 'Malaysia'),
    ('65', 'Singapura'),
    ('673', 'Brunei'),
    ('66', 'Thailand'),
    ('63', 'Filipina'),
    ('61', 'Australia'),
  ];

  static const minQty = 1;
  static const maxQty = 99;

  TopengDetail? _detail;
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  int _qty = minQty;
  String _dial = '62';
  bool _busy = false;
  String? _orderError;

  TopengDetail? get detail => _detail;
  LoadStatus get status => _status;
  String? get error => _error;
  int get qty => _qty;
  String get dial => _dial;
  bool get busy => _busy;

  String? get orderError => _orderError;

  bool get canDecrease => _qty > minQty;
  bool get canIncrease => _qty < maxQty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _detail = await _repo.fetchTopeng(id);
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void decrease() {
    if (!canDecrease) return;
    _qty--;
    notifyListeners();
  }

  void increase() {
    if (!canIncrease) return;
    _qty++;
    notifyListeners();
  }

  void selectDial(String code) {
    _dial = code;
    notifyListeners();
  }

  String fullPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    return digits.isEmpty ? '' : '+$_dial$digits';
  }

  String? validatePhone(String raw) {
    final full = fullPhone(raw);
    if (full.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (_dial == '62') return Validators.phone(full, required: true);
    final n = full.length - 1 - _dial.length;
    if (n < 6 || n > 14) return 'Nomor tidak valid';
    return null;
  }

  Future<TopengOrder?> placeOrder({required String phone, required String message}) async {
    final t = _detail?.topeng;
    if (t == null) return null;
    _busy = true;
    _orderError = null;
    notifyListeners();
    try {
      return await _repo.createOrder(
        topengId: t.id,
        qty: _qty,
        buyerPhone: fullPhone(phone),
        message: Validators.clean(message),
      );
    } on ApiException catch (e) {
      _orderError = e.message;
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
