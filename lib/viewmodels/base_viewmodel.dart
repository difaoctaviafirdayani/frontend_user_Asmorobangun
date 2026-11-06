import 'package:flutter/foundation.dart';

enum LoadStatus { loading, success, error }

abstract class BaseViewModel extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

typedef PickedImage = ({List<int> bytes, String name});

abstract class LoadableViewModel<T> extends BaseViewModel {
  T? _data;
  LoadStatus _status = LoadStatus.loading;
  String? _error;

  T? get data => _data;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<T> fetch();

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
