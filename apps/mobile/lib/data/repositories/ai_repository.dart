import '../../domain/models/ai_chat.dart';
import '../../domain/models/quiz.dart';
import 'repositories.dart';

abstract interface class AiRepository {
  Future<List<QuizQuestion>> generateQuiz();
  Future<ChatReply> chat(List<ChatMessage> messages);
}

class UnavailableAiRepository implements AiRepository {
  const UnavailableAiRepository();

  static const _error = AppException(
    'O assistente está disponível no modo API. Entre com sua conta para usar a IA.',
  );

  @override
  Future<List<QuizQuestion>> generateQuiz() => Future.error(_error);

  @override
  Future<ChatReply> chat(List<ChatMessage> messages) => Future.error(_error);
}
