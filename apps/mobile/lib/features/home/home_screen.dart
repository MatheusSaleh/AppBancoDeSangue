import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../shared/widgets/common.dart';
import '../auth/session_view_model.dart';
import '../donations/donor_view_model.dart';
import 'eligibility_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _destinations = [
    _Destination('Histórico', 'Suas doações', Icons.history, '/doacoes'),
    _Destination(
      'Guia de doação',
      'Antes, durante e depois',
      Icons.menu_book_outlined,
      '/guia',
    ),
    _Destination(
      'Compatibilidade',
      'Tipos sanguíneos',
      Icons.bloodtype_outlined,
      '/compatibilidade',
    ),
    _Destination(
      'Quiz',
      'Teste seus conhecimentos',
      Icons.quiz_outlined,
      '/quiz',
    ),
    _Destination(
      'Notícias',
      'Comunicados',
      Icons.article_outlined,
      '/noticias',
    ),
    _Destination('Sobre', 'O projeto', Icons.info_outline, '/sobre'),
  ];

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorViewModel>();
    final config = context.read<AppConfig>();
    final name = donor.profile.name.trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isEmpty ? 'Olá!' : 'Olá, $name!'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/perfil'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionViewModel>().signOut(),
          ),
        ],
      ),
      body: switch (donor.state) {
        LoadState.idle || LoadState.loading => const LoadingView(),
        LoadState.error => MessageView(
          icon: Icons.cloud_off,
          title: 'Não foi possível carregar seus dados',
          message: donor.error,
          actionLabel: 'Tentar novamente',
          onAction: donor.load,
        ),
        LoadState.ready => RefreshIndicator(
          onRefresh: donor.load,
          child: ResponsiveListView(
            children: [
              if (config.isDemo) ...[
                const DemoNotice(
                  'Modo demonstração: dados salvos apenas neste dispositivo.',
                ),
                const SizedBox(height: 16),
              ],
              EligibilityCard(
                result: donor.eligibility,
                today: donor.today,
                onCompleteProfile: () => context.push('/perfil'),
                onRegister: () => context.push('/doacoes/nova'),
              ),
              const SizedBox(height: 16),
              _Stats(donor: donor),
              const SizedBox(height: 24),
              Text('Explorar', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _DestinationGrid(destinations: _destinations),
            ],
          ),
        ),
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.donor});

  final DonorViewModel donor;

  @override
  Widget build(BuildContext context) {
    final eligibility = donor.eligibility;
    final max = eligibility.rules?.maxPerYear;
    // IntrinsicHeight keeps the three tiles the same height even when
    // labels wrap differently.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              label: 'Doações registradas',
              value: '${donor.history.length}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Últimos 12 meses',
              value: max == null
                  ? '${eligibility.donationsInLast12Months}'
                  : '${eligibility.donationsInLast12Months}/$max',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Tipo sanguíneo',
              value: donor.profile.bloodType?.label ?? '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.title, this.subtitle, this.icon, this.route);

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _DestinationGrid extends StatelessWidget {
  const _DestinationGrid({required this.destinations});

  final List<_Destination> destinations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 3 : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final d in destinations)
              SizedBox(
                width: width,
                child: _DestinationCard(destination: d),
              ),
          ],
        );
      },
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(destination.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(destination.icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(destination.title, style: theme.textTheme.titleSmall),
              Text(destination.subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
