import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/repositories/ai_repository.dart';
import 'data/repositories/repositories.dart';
import 'features/auth/session_view_model.dart';
import 'features/donations/donor_view_model.dart';

/// Everything the UI depends on. Built once in `main.dart` (or in tests with
/// fakes) and exposed through `provider`.
class AppDependencies {
  const AppDependencies({
    required this.config,
    required this.auth,
    required this.donations,
    required this.profiles,
    required this.news,
    this.ai = const UnavailableAiRepository(),
    this.clock,
  });

  final AppConfig config;
  final AuthRepository auth;
  final DonationRepository donations;
  final ProfileRepository profiles;
  final NewsRepository news;
  final AiRepository ai;
  final DateTime Function()? clock;
}

class BloodDonationApp extends StatefulWidget {
  const BloodDonationApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<BloodDonationApp> createState() => _BloodDonationAppState();
}

class _BloodDonationAppState extends State<BloodDonationApp> {
  late final SessionViewModel _session;
  late final DonorViewModel _donor;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final deps = widget.dependencies;
    _session = SessionViewModel(deps.auth);
    _donor = DonorViewModel(
      auth: deps.auth,
      donations: deps.donations,
      profiles: deps.profiles,
      clock: deps.clock,
    );
    _router = buildRouter(_session);
  }

  @override
  void dispose() {
    _router.dispose();
    _donor.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    return MultiProvider(
      providers: [
        Provider.value(value: deps.config),
        Provider.value(value: deps.auth),
        Provider.value(value: deps.news),
        Provider.value(value: deps.ai),
        ChangeNotifierProvider.value(value: _session),
        ChangeNotifierProvider.value(value: _donor),
      ],
      child: MaterialApp.router(
        title: 'Banco de Sangue',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        routerConfig: _router,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
