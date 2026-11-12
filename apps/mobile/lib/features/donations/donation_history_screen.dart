import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/formatters.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/donation.dart';
import '../../shared/widgets/common.dart';
import 'donor_view_model.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas doações')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/doacoes/nova'),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: switch (donor.state) {
        LoadState.idle || LoadState.loading => const LoadingView(),
        LoadState.error => MessageView(
          icon: Icons.cloud_off,
          title: 'Erro ao carregar doações',
          message: donor.error,
          actionLabel: 'Tentar novamente',
          onAction: donor.load,
        ),
        LoadState.ready when donor.history.isEmpty => _Empty(donor: donor),
        LoadState.ready => _List(history: donor.history),
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.donor});

  final DonorViewModel donor;

  @override
  Widget build(BuildContext context) {
    final isDemo = context.read<AppConfig>().isDemo;
    return MessageView(
      icon: Icons.water_drop_outlined,
      title: 'Nenhuma doação registrada',
      message: isDemo
          ? 'Registre sua primeira doação ou carregue registros de exemplo '
                'para explorar o app.'
          : 'Registre sua primeira doação para acompanhar seu histórico.',
      actionLabel: isDemo ? 'Carregar exemplos' : null,
      onAction: isDemo ? donor.addSampleDonations : null,
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.history});

  final List<Donation> history;

  @override
  Widget build(BuildContext context) {
    return ResponsiveListView(
      children: [
        for (final (index, donation) in history.indexed) ...[
          _DonationTile(donation: donation, ordinal: history.length - index),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 72), // room for the FAB
      ],
    );
  }
}

class _DonationTile extends StatelessWidget {
  const _DonationTile({required this.donation, required this.ordinal});

  final Donation donation;
  final int ordinal;

  Future<void> _delete(BuildContext context) async {
    final donor = context.read<DonorViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text('Doação de ${formatDate(donation.date)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await donor.deleteDonation(donation.id);
      if (context.mounted) {
        showMessage(
          context,
          'Registro excluído.',
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => donor.restoreDonation(donation),
          ),
        );
      }
    } on AppException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (donation.location.isNotEmpty) donation.location,
      if (donation.notes.isNotEmpty) donation.notes,
    ];
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '$ordinalª',
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(
          formatLongDate(donation.date),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: details.isEmpty ? null : Text(details.join('\n')),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções',
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/doacoes/${donation.id}/editar');
            } else {
              _delete(context);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}
