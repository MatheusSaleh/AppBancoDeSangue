import 'package:appbancodesangue/app.dart';
import 'package:appbancodesangue/data/local/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> _pumpApp(WidgetTester tester, {InMemoryStore? store}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  final deps = await demoDependencies(store: store);
  await tester.pumpWidget(BloodDonationApp(dependencies: deps));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  // Lazy lists only build children near the viewport: scroll until built.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// `tester.pageBack()` looks for flutter/material's BackButton, while the app
/// uses material_ui's, so tap it by its localized tooltip instead.
Future<void> _goBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Voltar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'bottom navigation preserves quiz progress and disappears on logout',
    (tester) async {
      await _pumpApp(tester);
      expect(find.byType(NavigationBar), findsNothing);
      await _tapText(tester, 'Entrar como visitante');
      await tester.tap(find.byKey(const ValueKey('nav-quiz')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await _tapText(tester, 'Apenas homens');
      await tester.tap(find.byKey(const ValueKey('nav-history')));
      await tester.pumpAndSettle();
      expect(find.text('Minhas doações'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-quiz')));
      await tester.pumpAndSettle();
      expect(find.text('Não é bem assim.'), findsOneWidget);
      await _tapText(tester, 'Próxima');
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-quiz')));
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 2 de 5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sair'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets(
    'home tab restores nested navigation and reselecting returns to its root',
    (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Entrar como visitante');
      await _tapText(tester, 'Guia de doação');
      await _tapText(tester, 'Antes da doação');
      await tester.tap(find.byKey(const ValueKey('nav-history')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(find.text('Verifique os requisitos básicos'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(find.text('Olá!'), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsNothing);
    },
  );

  testWidgets('demo flow: guest login → profile → register → countdown', (
    tester,
  ) async {
    await _pumpApp(tester);

    // Unauthenticated users land on the login screen.
    expect(find.text('Entrar como visitante'), findsOneWidget);
    await _tapText(tester, 'Entrar como visitante');

    // Home asks to complete the profile before computing eligibility.
    expect(find.text('Complete seu perfil'), findsOneWidget);
    await _tapText(tester, 'Completar perfil');

    await tester.enterText(find.byType(TextFormField).first, 'Ana Souza');
    await _tapText(tester, 'Feminino');
    await _tapText(tester, 'Salvar perfil');

    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.text('Pronto para a primeira doação?'), findsOneWidget);

    // Register a donation today (default date in the form).
    await _tapText(tester, 'Registrar doação');
    expect(find.byType(NavigationBar), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Hemocentro Regional');
    await _tapText(tester, 'Salvar');

    // Women must wait 90 days.
    expect(find.text('Próxima doação em 90 dias'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('history: empty state, sample data and delete with undo', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapText(tester, 'Entrar como visitante');
    await _tapText(tester, 'Histórico');

    expect(find.text('Nenhuma doação registrada'), findsOneWidget);
    await _tapText(tester, 'Carregar exemplos');
    expect(
      find.text(
        'Hemocentro (exemplo)\nRegistro de exemplo do modo '
        'demonstração.',
      ),
      findsNWidgets(3),
    );

    await tester.tap(find.byTooltip('Opções').first);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Excluir');
    await _tapText(tester, 'Excluir'); // confirm dialog
    expect(find.byTooltip('Opções'), findsNWidgets(2));

    await _tapText(tester, 'Desfazer');
    expect(find.byTooltip('Opções'), findsNWidgets(3));
  });

  testWidgets('session is restored and sign out returns to login', (
    tester,
  ) async {
    final store = InMemoryStore();
    await _pumpApp(tester, store: store);
    await _tapText(tester, 'Entrar como visitante');
    expect(find.byTooltip('Sair'), findsOneWidget);

    // Simulate an app restart with the same storage.
    await tester.pumpWidget(const SizedBox());
    await _pumpApp(tester, store: store);
    expect(find.byTooltip('Sair'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar como visitante'), findsOneWidget);
  });

  testWidgets('quiz shows explanation and final score', (tester) async {
    await _pumpApp(tester);
    await _tapText(tester, 'Entrar como visitante');
    await _tapText(tester, 'Quiz');

    expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    await _tapText(tester, 'Apenas homens');
    expect(find.text('Não é bem assim.'), findsOneWidget);
    await _tapText(tester, 'Próxima');

    final answers = [
      '60 dias para homens e 90 dias para mulheres',
      'Porque o sangue não pode ser fabricado e é indispensável em '
          'cirurgias, tratamentos e emergências',
      'O sangue é coletado por uma agulha, com material estéril e '
          'descartável',
      'Passa por testes, é separado em componentes e armazenado',
    ];
    for (final (i, answer) in answers.indexed) {
      await _tapText(tester, answer);
      expect(find.text('Correto!'), findsOneWidget);
      final isLast = i == answers.length - 1;
      await _tapText(tester, isLast ? 'Ver resultado' : 'Próxima');
    }

    expect(find.text('4 de 5 acertos'), findsOneWidget);
    expect(find.text('Parabéns, você é um doador exemplar!'), findsOneWidget);
  });

  testWidgets('guide and compatibility screens render content', (tester) async {
    await _pumpApp(tester);
    await _tapText(tester, 'Entrar como visitante');

    await _tapText(tester, 'Guia de doação');
    await _tapText(tester, 'Antes da doação');
    expect(find.text('Verifique os requisitos básicos'), findsOneWidget);
    await _goBack(tester);
    await _goBack(tester);

    await _tapText(tester, 'Compatibilidade');
    expect(find.text('O- pode doar para'), findsOneWidget);
    await _tapText(tester, 'AB+');
    expect(find.text('AB+ pode receber de'), findsOneWidget);
  });
}
