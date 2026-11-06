import '../core/api.dart';
import '../repositories/topeng_repository.dart';
import 'base_viewmodel.dart';

class ChatMessage {
  final bool fromUser;
  final String text;
  ChatMessage(this.fromUser, this.text);
}

class TopengAssistantViewModel extends BaseViewModel {
  final TopengRepository _repo;
  TopengAssistantViewModel(this._repo);

  static const suggestions = [
    'Apa makna warna topeng?',
    'Siapa itu tokoh Klana?',
    'Bagaimana cara merawat topeng kayu?',
    'Bisa pesan topeng custom?',
  ];

  final List<ChatMessage> _messages = [
    ChatMessage(false,
        'Halo! Aku Asisten Topeng. Tanya apa saja soal Topeng Malangan: sejarah, tokoh, makna warna, perawatan, sampai katalog di sini.'),
  ];
  bool _busy = false;

  List<ChatMessage> get messages => _messages;
  bool get busy => _busy;

  bool get isFresh => _messages.length == 1;

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    final history = _messages
        .skip(1)
        .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
        .toList();
    _messages.add(ChatMessage(true, text));
    _busy = true;
    notifyListeners();
    try {
      final reply = await _repo.askAssistant(text, history);
      _messages.add(ChatMessage(false, reply));
    } on ApiException catch (e) {
      _messages.add(ChatMessage(false, 'Maaf, ada kendala: ${e.message}'));
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
