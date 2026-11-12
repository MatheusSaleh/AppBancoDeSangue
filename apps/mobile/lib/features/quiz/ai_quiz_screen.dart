import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/quiz.dart';
import '../../shared/widgets/common.dart';
import 'quiz_screen.dart';

class AiQuizScreen extends StatefulWidget {
  const AiQuizScreen({super.key});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  List<QuizQuestion>? _questions;
  bool _loading = false;
  bool _local = false;
  int _generation = 0;
  String? _error;

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await context.read<AiRepository>().generateQuiz();
      if (mounted) {
        setState(() {
          _questions = questions;
          _generation++;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_local || context.read<AppConfig>().isDemo) return const QuizScreen();
    if (_questions != null && !_loading && _error == null) {
      return QuizScreen(
        key: ValueKey(_generation),
        questions: _questions!,
        isAi: true,
        onNewQuiz: _generate,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz com IA')),
      body: _loading
          ? const LoadingView(label: 'Gerando questionário…')
          : ResponsiveListView(
              maxWidth: 640,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Aprenda algo novo a cada rodada',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'A IA monta 5 perguntas sobre doação de sangue, com alternativas e explicações. '
                  'Os temas e a ordem das respostas variam a cada questionário.',
                ),
                const SizedBox(height: 16),
                const DemoNotice(
                  'Conteúdo educativo gerado por IA. Pode conter erros e não determina '
                  'se você pode doar. Confirme orientações no hemocentro.',
                  icon: Icons.info_outline,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    _error == null
                        ? 'Gerar questionário com IA'
                        : 'Tentar novamente',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _local = true),
                  child: const Text('Usar quiz do app'),
                ),
              ],
            ),
    );
  }
}
