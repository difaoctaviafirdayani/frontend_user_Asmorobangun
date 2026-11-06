import '../core/api.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../repositories/forum_repository.dart';
import 'base_viewmodel.dart';

class ThreadDetailViewModel extends BaseViewModel {
  final ForumRepository _repo;
  final String threadId;
  ThreadDetailViewModel(this._repo, this.threadId);

  ForumThread? _thread;
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  bool _sending = false;
  String? _sendError;

  ForumThread? get thread => _thread;
  LoadStatus get status => _status;
  String? get error => _error;
  bool get sending => _sending;

  String? get sendError => _sendError;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _thread = await _repo.fetchThread(threadId);
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> sendReply(String text) async {
    _sending = true;
    _sendError = null;
    notifyListeners();
    try {
      await _repo.postReply(threadId, Validators.clean(text));
    } on ApiException catch (e) {
      _sendError = e.message;
      _sending = false;
      notifyListeners();
      return false;
    }
    _sending = false;
    notifyListeners();
    await load();
    return true;
  }
}
