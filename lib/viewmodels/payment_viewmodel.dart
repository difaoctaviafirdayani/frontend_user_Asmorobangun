import '../core/api.dart';
import '../repositories/payment_repository.dart';
import 'base_viewmodel.dart';

class PaymentViewModel extends BaseViewModel {
  final PaymentRepository _repo;
  final String kind;
  final String id;
  final Map<String, dynamic> methods;
  PaymentViewModel(this._repo, {required this.kind, required this.id, this.methods = const {}}) {
    final first = available.isEmpty ? null : available.first;
    if (first != null) selectMethod(first);
  }

  String? _method;
  PickedImage? _picked;
  bool _busy = false;
  String? _error;

  LoadStatus _infoStatus = LoadStatus.loading;
  Map<String, dynamic> _info = const {};
  String? _infoError;
  int _infoSeq = 0;

  List<String> get available {
    bool on(String m) {
      final cfg = methods[m];
      return cfg is! Map || cfg['enabled'] != false;
    }

    final all = kind == 'topeng' ? ['qris', 'transfer'] : ['qris', 'transfer', 'cash'];
    return all.where(on).toList();
  }

  String? get method => _method;
  PickedImage? get picked => _picked;
  bool get busy => _busy;

  String? get error => _error;

  LoadStatus get infoStatus => _infoStatus;
  Map<String, dynamic> get info => _info;
  String? get infoError => _infoError;

  void selectMethod(String m) {
    _method = m;
    _picked = null;
    if (m == 'cash') {
      _info = const {};
      _infoStatus = LoadStatus.success;
    } else {
      _loadInfo(m);
    }
    notifyListeners();
  }

  Future<void> _loadInfo(String m) async {
    final seq = ++_infoSeq;
    _infoStatus = LoadStatus.loading;
    _infoError = null;
    try {
      final data = await _repo.fetchInfo(kind, id, m);
      if (seq != _infoSeq) return;
      _info = data;
      _infoStatus = LoadStatus.success;
    } catch (e) {
      if (seq != _infoSeq) return;
      _infoError = e.toString();
      _infoStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  void setPicked(PickedImage file) {
    _picked = file;
    notifyListeners();
  }

  Future<bool> chooseCash() => _run(() => _repo.chooseCash(kind, id));

  Future<bool> uploadProof(String m) {
    final f = _picked;
    if (f == null) {
      _error = 'Pilih foto bukti pembayaran dulu.';
      notifyListeners();
      return Future.value(false);
    }
    return _run(() => _repo.uploadProof(kind, id, m, f.bytes, f.name));
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
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
