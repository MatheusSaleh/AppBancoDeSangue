/// Which backend the app talks to, chosen at build time:
///
/// ```sh
/// flutter run                                    # demo (default, local data)
/// flutter run --dart-define=BACKEND=api          # TypeScript API (apps/api)
/// flutter run --dart-define=BACKEND=api --dart-define=API_URL=http://10.0.2.2:3000
/// ```
enum Backend { demo, api }

class AppConfig {
  const AppConfig({required this.backend, this.apiUrl = defaultApiUrl});

  static const defaultApiUrl = 'http://localhost:3000';

  factory AppConfig.fromEnvironment() {
    const backend = String.fromEnvironment('BACKEND', defaultValue: 'demo');
    const apiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: defaultApiUrl,
    );
    return AppConfig(
      backend: backend == 'api' ? Backend.api : Backend.demo,
      apiUrl: apiUrl,
    );
  }

  final Backend backend;

  /// Base URL of the API. On the Android emulator the host machine is
  /// reachable at `10.0.2.2`.
  final String apiUrl;

  bool get isDemo => backend == Backend.demo;
}
