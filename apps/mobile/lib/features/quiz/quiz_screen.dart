import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/common.dart';
import 'quiz_questions.dart';
import 'quiz_view_model.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizViewModel(quizQuestions),
      child: Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Consumer<QuizViewModel>(
          builder: (context, quiz, _) =>
              quiz.finished ? _Result(quiz: quiz) : _Question(quiz: quiz),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.quiz});

  final QuizViewModel quiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final question = quiz.current;
    final total = quiz.questions.length;

    return ResponsiveListView(
      maxWidth: 640,
      children: [
        LinearProgressIndicator(
          value: quiz.progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          semanticsLabel: 'Progresso do quiz',
        ),
        const SizedBox(height: 16),
        Text(
          'Pergunta ${quiz.index + 1} de $total',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(question.text, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 24),
        for (final (i, option) in question.options.indexed) ...[
          _OptionButton(
            text: option,
            state: !quiz.answered
                ? _OptionState.idle
                : i == question.correctIndex
                ? _OptionState.correct
                : i == quiz.selected
                ? _OptionState.wrong
                : _OptionState.disabled,
            onTap: () => quiz.answer(i),
          ),
          const SizedBox(height: 12),
        ],
        if (quiz.answered) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Card(
              color: quiz.lastAnswerCorrect
                  ? scheme.primaryContainer
                  : scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.lastAnswerCorrect ? 'Correto!' : 'Não é bem assim.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(question.explanation),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: quiz.next,
            child: Text(quiz.index + 1 < total ? 'Próxima' : 'Ver resultado'),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, disabled }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (
      Color? bg,
      Color? fg,
      IconData? icon,
      String? semantic,
    ) = switch (state) {
      _OptionState.correct => (
        scheme.primary,
        scheme.onPrimary,
        Icons.check_circle,
        'resposta correta',
      ),
      _OptionState.wrong => (
        scheme.error,
        scheme.onError,
        Icons.cancel,
        'sua resposta, incorreta',
      ),
      _ => (null, null, null, null),
    };
    return Semantics(
      hint: semantic,
      child: OutlinedButton(
        onPressed: state == _OptionState.idle ? onTap : () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon)],
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.quiz});

  final QuizViewModel quiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: ResponsiveBody(
          maxWidth: 520,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '${quiz.correctCount} de ${quiz.questions.length} acertos',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                quiz.resultMessage,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: quiz.restart,
                icon: const Icon(Icons.replay),
                label: const Text('Refazer quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
