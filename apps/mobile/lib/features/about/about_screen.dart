import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../shared/widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = context.read<AppConfig>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ResponsiveListView(
        children: [
          Text('Banco de Sangue', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Aplicativo desenvolvido em 2023 como Projeto de Iniciação '
            'Científica no Centro de Pesquisas em Informática da FEMA, com o '
            'objetivo de informar e incentivar a doação de sangue.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Matheus Saleh'),
                  subtitle: Text('Desenvolvimento'),
                ),
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Gabriel Eduardo'),
                  subtitle: Text('Desenvolvimento'),
                ),
                ListTile(
                  leading: Icon(Icons.school_outlined),
                  title: Text('Centro de Pesquisas em Informática'),
                  subtitle: Text('FEMA'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Versão 2.0 (2026)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text(
            'Modernização com nova arquitetura, cálculo da próxima data de '
            'doação, compatibilidade sanguínea, quiz com explicações e testes '
            'automatizados.',
          ),
          const SizedBox(height: 16),
          Text(
            config.isDemo
                ? 'Backend: demonstração (dados locais).'
                : 'Backend: API própria (apps/api).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'As informações têm caráter educativo e não substituem a '
            'orientação dos profissionais do hemocentro.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Banco de Sangue',
            ),
            child: const Text('Licenças de código aberto'),
          ),
        ],
      ),
    );
  }
}
