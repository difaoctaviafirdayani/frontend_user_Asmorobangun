import '../core/api.dart';
import '../models/models.dart';

class ForumRepository {
  final ApiClient _api;
  ForumRepository(this._api);

  static const defaultCategories = [
    'Diskusi Umum',
    'Kelas Tari',
    'Karawitan',
    'Topeng',
    'Acara & Booking',
  ];

  Future<List<ThreadSummary>> fetchThreads() async {
    final res = await _api.get('/forum');
    return mapList(res['threads'], ThreadSummary.fromJson);
  }

  Future<ForumThread> fetchThread(String id) async {
    final res = await _api.get('/forum/${Uri.encodeComponent(id)}');
    return ForumThread.fromJson(res['thread'] as Map<String, dynamic>);
  }

  Future<List<String>> fetchCategories() async {
    try {
      final res = await _api.get('/forum/categories');
      final list = res['categories'];
      if (list is List && list.isNotEmpty) {
        return list.map((e) => e.toString()).toList();
      }
      return defaultCategories;
    } on ApiException {
      return defaultCategories;
    }
  }

  Future<void> createThread({
    required String title,
    required String content,
    required String category,
  }) async {
    await _api.post('/forum', body: {
      'title': title,
      'content': content,
      'category': category,
    });
  }

  Future<void> postReply(String threadId, String content) async {
    await _api.post('/forum/${Uri.encodeComponent(threadId)}/replies', body: {'content': content});
  }
}