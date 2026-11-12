import 'package:flutter/foundation.dart';

import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/ai_chat.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel(this._repository);

  final AiRepository _repository;
  final List<ChatMessage> _messages = [];
  bool _disposed = false;
  bool busy = false;
  String? error;
  String? pending;
  List<String> suggestions = List.of(initialSuggestions);

  static const initialSuggestions = [
    'Como me preparar para doar?',
    'O que acontece com o sangue doado?',
    'Como funciona a triagem?',
  ];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> send(String content) async {
    final text = content.trim();
    if (busy || text.isEmpty || text.length > 1000) return;
    busy = true;
    pending = text;
    error = null;
    notifyListeners();
    final history =
        _messages
            .skip(_messages.length > 10 ? _messages.length - 10 : 0)
            .toList()
          ..add(ChatMessage(role: 'user', content: text));
    while (history.fold<int>(0, (n, m) => n + m.content.length) > 9000 &&
        history.length > 1) {
      history.removeRange(0, 2);
    }
    try {
      final response = await _repository.chat(history);
      if (_disposed) return;
      _messages.addAll([
        ChatMessage(role: 'user', content: text),
        ChatMessage(role: 'assistant', content: response.reply),
      ]);
      suggestions = response.suggestions;
      pending = null;
    } on AppException catch (e) {
      if (_disposed) return;
      error = e.message;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    if (busy) return;
    _messages.clear();
    pending = null;
    error = null;
    suggestions = List.of(initialSuggestions);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
