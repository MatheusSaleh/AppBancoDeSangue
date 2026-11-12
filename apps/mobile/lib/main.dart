import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/api/api_client.dart';
import 'data/api/api_repositories.dart';
import 'data/api/token_store.dart';
import 'data/local/key_value_store.dart';
import 'data/local/local_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final config = AppConfig.fromEnvironment();
  final dependencies = switch (config.backend) {
    Backend.demo => await _demoDependencies(config),
    Backend.api => await _apiDependencies(config),
  };

  runApp(BloodDonationApp(dependencies: dependencies));
}

Future<AppDependencies> _demoDependencies(AppConfig config) async {
  final store = SharedPreferencesStore();
  final auth = LocalAuthRepository(store);
  await auth.restore();
  return AppDependencies(
    config: config,
    auth: auth,
    donations: LocalDonationRepository(store),
    profiles: LocalProfileRepository(store),
    news: const DemoNewsRepository(),
  );
}

Future<AppDependencies> _apiDependencies(AppConfig config) async {
  final client = ApiClient(baseUrl: config.apiUrl);
  final auth = ApiAuthRepository(client, SecureTokenStore());
  await auth.restore();
  return AppDependencies(
    config: config,
    auth: auth,
    donations: ApiDonationRepository(client),
    profiles: ApiProfileRepository(client),
    news: ApiNewsRepository(client),
  );
}
