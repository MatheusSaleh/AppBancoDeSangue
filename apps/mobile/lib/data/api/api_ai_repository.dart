import '../../domain/models/ai_chat.dart';
import '../../domain/models/quiz.dart';
import '../repositories/ai_repository.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiAiRepository implements AiRepository {
  ApiAiRepository(this._client);

  final ApiClient _client;
  static const _timeout = Duration(seconds: 75);

  @override
  Future<List<QuizQuestion>> generateQuiz() async {
    final result = await _client.post('ai/quiz', {}, _timeout);
    try {
      final json = result! as Map<String, Object?>;
      final questions = (json['questions']! as List<Object?>).map((item) {
        final q = item! as Map<String, Object?>;
        final options = (q['options']! as List<Object?>).cast<String>();
        final correct = q['correctIndex']! as int;
        if (options.length != 4 || correct < 0 || correct >= 4) {
          throw const FormatException();
        }
        return QuizQuestion(
          text: q['text']! as String,
          options: options,
          correctIndex: correct,
          explanation: q['explanation']! as String,
        );
      }).toList();
      if (questions.length != 5) throw const FormatException();
      return questions;
    } on Object {
      throw const AppException('Questionário inválido. Tente gerar novamente.');
    }
  }

  @override
  Future<ChatReply> chat(List<ChatMessage> messages) async {
    final result = await _client.post('ai/chat', {
      'messages': messages.map((m) => m.toJson()).toList(),
    }, _timeout);
    try {
      final json = result! as Map<String, Object?>;
      return ChatReply(
        reply: json['reply']! as String,
        suggestions: (json['suggestions']! as List<Object?>).cast<String>(),
      );
    } on Object {
      throw const AppException('Resposta inválida. Tente enviar novamente.');
    }
  }
}
