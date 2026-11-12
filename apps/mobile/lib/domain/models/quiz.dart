class QuizQuestion {
  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String text;
  final List<String> options;
  final int correctIndex;

  /// Shown after answering, so the quiz teaches instead of only scoring.
  final String explanation;
}

/// Result messages from the original 2023 quiz.
///
/// The original scoring gave +10 per correct and -2 per wrong answer with
/// thresholds 41/31/21/1 over five questions. That is equivalent to the
/// number of correct answers below, which is easier to read and to test.
String quizResultMessage({required int correct, required int total}) {
  final legacyScore = correct * 10 - (total - correct) * 2;
  if (legacyScore >= 41) {
    return 'Você é um verdadeiro herói da doação de sangue!';
  } else if (legacyScore >= 31) {
    return 'Parabéns, você é um doador exemplar!';
  } else if (legacyScore >= 21) {
    return 'Seu esforço é apreciado, mas ainda há mais a aprender sobre a '
        'doação de sangue.';
  } else if (legacyScore >= 1) {
    return 'É louvável que você tenha interesse, mas é importante estudar '
        'mais sobre a doação de sangue.';
  }
  return 'Parece que você precisa aprender mais sobre a importância da '
      'doação de sangue.';
}
