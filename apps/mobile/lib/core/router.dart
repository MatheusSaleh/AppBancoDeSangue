import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/session_view_model.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/compatibility/compatibility_screen.dart';
import '../features/donations/donation_form_screen.dart';
import '../features/donations/donation_history_screen.dart';
import '../features/guide/guide_screens.dart';
import '../features/home/home_screen.dart';
import '../features/news/news_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/quiz/quiz_screen.dart';

const _publicRoutes = {'/login', '/cadastro', '/redefinir-senha'};

/// Declarative routes with a single auth guard. Replaces the 2023 mix of
/// StreamBuilder + manual pushReplacement, which stacked duplicate screens.
GoRouter buildRouter(SessionViewModel session) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      // Wait for the first auth event (the API session is restored
      // asynchronously) to avoid flashing the login screen.
      if (!session.initialized) return null;
      final isPublic = _publicRoutes.contains(state.matchedLocation);
      if (!session.isSignedIn) return isPublic ? null : '/login';
      if (isPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/cadastro', builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: '/redefinir-senha',
        builder: (_, state) =>
            ResetPasswordScreen(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(path: 'perfil', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: 'doacoes',
            builder: (_, _) => const DonationHistoryScreen(),
            routes: [
              GoRoute(
                path: 'nova',
                builder: (_, _) => const DonationFormScreen(),
              ),
              GoRoute(
                path: ':id/editar',
                builder: (_, state) =>
                    DonationFormScreen(donationId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: 'guia',
            builder: (_, _) => const GuideScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (_, state) =>
                    GuideStageScreen(slug: state.pathParameters['slug']!),
              ),
            ],
          ),
          GoRoute(path: 'quiz', builder: (_, _) => const QuizScreen()),
          GoRoute(path: 'noticias', builder: (_, _) => const NewsScreen()),
          GoRoute(
            path: 'compatibilidade',
            builder: (_, _) => const CompatibilityScreen(),
          ),
          GoRoute(path: 'sobre', builder: (_, _) => const AboutScreen()),
        ],
      ),
    ],
  );
}
