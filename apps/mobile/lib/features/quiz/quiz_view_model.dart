import 'package:flutter/foundation.dart';

import '../../domain/models/quiz.dart';

/// Quiz flow: answer → feedback with explanation → next question → result.
class QuizViewModel extends ChangeNotifier {
  QuizViewModel(this.questions) : assert(questions.isNotEmpty);

  final List<QuizQuestion> questions;

  int _index = 0;
  int _correct = 0;
  int? _selected;

  int get index => _index;
  int get correctCount => _correct;
  int? get selected => _selected;
  bool get answered => _selected != null;
  bool get finished => _index >= questions.length;
  QuizQuestion get current => questions[_index];
  double get progress => _index / questions.length;

  bool get lastAnswerCorrect =>
      _selected != null && _selected == current.correctIndex;

  String get resultMessage =>
      quizResultMessage(correct: _correct, total: questions.length);

  void answer(int option) {
    if (answered || finished) return;
    _selected = option;
    if (option == current.correctIndex) _correct++;
    notifyListeners();
  }

  void next() {
    if (!answered) return;
    _selected = null;
    _index++;
    notifyListeners();
  }

  void restart() {
    _index = 0;
    _correct = 0;
    _selected = null;
    notifyListeners();
  }
}
