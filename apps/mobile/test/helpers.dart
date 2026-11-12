import 'package:appbancodesangue/app.dart';
import 'package:appbancodesangue/core/config.dart';
import 'package:appbancodesangue/data/local/key_value_store.dart';
import 'package:appbancodesangue/data/local/local_repositories.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Fixed "today" so date-based assertions are deterministic.
final testToday = DateTime(2026, 11, 11, 10);

Future<AppDependencies> demoDependencies({InMemoryStore? store}) async {
  await initializeDateFormatting('pt_BR');
  final s = store ?? InMemoryStore();
  final auth = LocalAuthRepository(s);
  await auth.restore();
  return AppDependencies(
    config: const AppConfig(backend: Backend.demo),
    auth: auth,
    donations: LocalDonationRepository(s),
    profiles: LocalProfileRepository(s),
    news: const DemoNewsRepository(),
    clock: () => testToday,
  );
}
