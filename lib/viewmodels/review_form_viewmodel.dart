import '../core/api.dart';
import '../models/models.dart';
import '../repositories/review_repository.dart';
import 'base_viewmodel.dart';

class ReviewFormViewModel extends BaseViewModel {
  final ReviewRepository _repo;
  final String basePath;
  final Review? existing;
  ReviewFormViewModel(this._repo, this.basePath, this.existing) : _rating = existing?.rating ?? 0;

  static const maxImageBytes = 5 * 1024 * 1024;

  int _rating;
  PickedImage? _picked;
  bool _removeImage = false;
  bool _busy = false;
  String? _error;

  int get rating => _rating;
  PickedImage? get picked => _picked;
  bool get busy => _busy;
  String? get error => _error;
  bool get editing => existing != null;
  bool get hasOldImage => (existing?.image ?? '').isNotEmpty && !_removeImage;

  void setRating(int value) {
    _rating = value;
    notifyListeners();
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void attachImage(PickedImage file) {
    if (file.bytes.length > maxImageBytes) {
      setError('Ukuran foto maksimal 5MB.');
      return;
    }
    _picked = file;
    _error = null;
    notifyListeners();
  }

  void removeOldImage() {
    _removeImage = true;
    notifyListeners();
  }

  Future<String?> submit(String rawComment) async {
    final text = rawComment.trim();
    if (_rating < 1) {
      setError('Pilih jumlah bintang dulu ya.');
      return null;
    }
    if (text.length < 3) {
      setError('Komentar minimal 3 karakter.');
      return null;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.save(basePath, rating: _rating, comment: text, editing: editing);
    } on ApiException catch (e) {
      _busy = false;
      _error = e.message;
      notifyListeners();
      return null;
    }

    var message = editing ? 'Ulasan diperbarui.' : 'Ulasan terkirim, makasih!';
    try {
      final file = _picked;
      if (file != null) {
        await _repo.uploadImage(basePath, file.bytes, file.name);
      } else if (_removeImage && (existing?.image ?? '').isNotEmpty) {
        await _repo.deleteImage(basePath);
      }
    } on ApiException catch (e) {
      message = 'Ulasan tersimpan, tapi foto gagal diunggah: ${e.message}';
    }
    return message;
  }

  Future<bool> delete() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.delete(basePath);
      return true;
    } on ApiException catch (e) {
      _busy = false;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
