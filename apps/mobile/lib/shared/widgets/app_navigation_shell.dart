import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Each tab has its own navigator; changing tabs preserves the current quiz,
/// conversation and scroll position. Authentication pages live outside it.
class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      // The screens inside the shell handle keyboard insets themselves.
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      bottomNavigationBar: keyboardVisible
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  key: ValueKey('nav-home'),
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Início',
                ),
                NavigationDestination(
                  key: ValueKey('nav-history'),
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Histórico',
                ),
                NavigationDestination(
                  key: ValueKey('nav-quiz'),
                  icon: Icon(Icons.quiz_outlined),
                  selectedIcon: Icon(Icons.quiz),
                  label: 'Quiz',
                ),
                NavigationDestination(
                  key: ValueKey('nav-chat'),
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'Assistente',
                ),
              ],
            ),
    );
  }
}
