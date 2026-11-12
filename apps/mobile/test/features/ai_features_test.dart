import 'dart:async';

import 'package:appbancodesangue/app.dart';
import 'package:appbancodesangue/core/config.dart';
import 'package:appbancodesangue/data/repositories/ai_repository.dart';
import 'package:appbancodesangue/data/repositories/repositories.dart';
import 'package:appbancodesangue/domain/models/ai_chat.dart';
import 'package:appbancodesangue/domain/models/quiz.dart';
import 'package:appbancodesangue/features/chat/chat_screen.dart';
import 'package:appbancodesangue/features/chat/chat_view_model.dart';
import 'package:appbancodesangue/features/quiz/ai_quiz_screen.dart';
import 'package:appbancodesangue/features/quiz/quiz_questions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

const answer = ChatReply(
  reply: 'Leve um documento oficial com foto.',
  suggestions: ['Posso usar documento digital?', 'Preciso estar alimentado?'],
);

class FakeAi implements AiRepository {
  int quizzes = 0;
  bool fail = false;
  Future<ChatReply>? pending;
  final requests = <List<ChatMessage>>[];

  @override
  Future<List<QuizQuestion>> generateQuiz() async {
    quizzes++;
    if (fail) throw const AppException('IA indisponível.');
    return quizQuestions;
  }

  @override
  Future<ChatReply> chat(List<ChatMessage> messages) async {
    requests.add(List.of(messages));
    if (fail) throw const AppException('Sem conexão.');
    return pending ?? answer;
  }
}

Future<void> pumpScreen(WidgetTester tester, Widget screen, FakeAi ai) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: const AppConfig(backend: Backend.api)),
        Provider<AiRepository>.value(value: ai),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tabs retain chat and drafts, handle keyboard insets and clear private state on logout',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final deps = await demoDependencies();
      await deps.auth.signInAsGuest();
      await tester.pumpWidget(
        BloodDonationApp(
          dependencies: AppDependencies(
            config: const AppConfig(backend: Backend.api),
            auth: deps.auth,
            donations: deps.donations,
            profiles: deps.profiles,
            news: deps.news,
            ai: FakeAi(),
            clock: deps.clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-chat')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Que documento levar?');
      await tester.tap(find.byTooltip('Enviar mensagem'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Minha próxima dúvida');
      tester.view.viewInsets = const FakeViewPadding(bottom: 700);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-chat')));
      await tester.pumpAndSettle();
      expect(find.text(answer.reply), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Minha próxima dúvida',
      );
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sair'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await deps.auth.signInAsGuest();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-chat')));
      await tester.pumpAndSettle();
      expect(find.text(answer.reply), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
    },
  );

  test(
    'chat retains context, bounds history and clears the conversation',
    () async {
      final ai = FakeAi();
      final vm = ChatViewModel(ai);
      addTearDown(vm.dispose);
      for (var i = 0; i < 8; i++) {
        await vm.send('Pergunta $i');
      }
      expect(ai.requests.last.length, 11);
      expect(ai.requests.last.first.content, 'Pergunta 2');
      expect(ai.requests.last.last.content, 'Pergunta 7');
      expect(vm.suggestions, answer.suggestions);
      vm.clear();
      expect(vm.messages, isEmpty);
      expect(vm.suggestions, ChatViewModel.initialSuggestions);
    },
  );

  test('chat failures are retryable and do not duplicate messages', () async {
    final ai = FakeAi()..fail = true;
    final vm = ChatViewModel(ai);
    addTearDown(vm.dispose);
    await vm.send('O que levar?');
    expect(vm.error, 'Sem conexão.');
    expect(vm.messages, isEmpty);
    expect(vm.pending, 'O que levar?');
    ai.fail = false;
    await vm.send(vm.pending!);
    expect(vm.messages.length, 2);
    expect(vm.error, isNull);
  });

  test(
    'chat prevents concurrent requests and ignores replies after disposal',
    () async {
      final response = Completer<ChatReply>();
      final ai = FakeAi()..pending = response.future;
      final vm = ChatViewModel(ai);
      final sending = vm.send('Como doar?');
      await vm.send('Outra pergunta');
      expect(ai.requests.length, 1);
      vm.dispose();
      response.complete(answer);
      await sending;
    },
  );

  testWidgets(
    'chat sends typed questions, contextual chips, and starts a new conversation',
    (tester) async {
      final ai = FakeAi();
      await pumpScreen(tester, const ChatScreen(), ai);
      expect(find.textContaining('Venice AI'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Que documento levar?');
      await tester.tap(find.byTooltip('Enviar mensagem'));
      await tester.pumpAndSettle();
      expect(find.text(answer.reply), findsOneWidget);
      await tester.tap(find.text(answer.suggestions.first));
      await tester.pumpAndSettle();
      expect(ai.requests.last.length, 3);
      expect(ai.requests.last.last.content, answer.suggestions.first);
      await tester.tap(find.byTooltip('Nova conversa'));
      await tester.pumpAndSettle();
      expect(find.text(answer.reply), findsNothing);
      expect(find.text(ChatViewModel.initialSuggestions.first), findsOneWidget);
    },
  );

  testWidgets('AI quiz generates, scores and generates another round', (
    tester,
  ) async {
    final ai = FakeAi();
    await pumpScreen(tester, const AiQuizScreen(), ai);
    await tester.tap(find.text('Gerar questionário com IA'));
    await tester.pumpAndSettle();
    expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tapVisible(
        tester,
        find.text(quizQuestions[i].options[quizQuestions[i].correctIndex]),
      );
      final next = find.text(i == 4 ? 'Ver resultado' : 'Próxima');
      await tapVisible(tester, next);
    }
    expect(find.text('5 de 5 acertos'), findsOneWidget);
    await tester.tap(find.text('Gerar outro questionário'));
    await tester.pumpAndSettle();
    expect(ai.quizzes, 2);
    expect(find.text('Pergunta 1 de 5'), findsOneWidget);
  });

  testWidgets('AI quiz offers recovery and bundled quiz when unavailable', (
    tester,
  ) async {
    final ai = FakeAi()..fail = true;
    await pumpScreen(tester, const AiQuizScreen(), ai);
    await tester.tap(find.text('Gerar questionário com IA'));
    await tester.pumpAndSettle();
    expect(find.text('IA indisponível.'), findsOneWidget);
    await tester.tap(find.text('Usar quiz do app'));
    await tester.pumpAndSettle();
    expect(find.text('Pergunta 1 de 5'), findsOneWidget);
  });
}
