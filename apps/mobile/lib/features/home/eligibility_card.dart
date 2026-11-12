import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../domain/rules/donation_eligibility.dart';

/// Shows when the donor can donate again, the core feature added in 2026.
class EligibilityCard extends StatelessWidget {
  const EligibilityCard({
    super.key,
    required this.result,
    required this.today,
    required this.onCompleteProfile,
    required this.onRegister,
  });

  final EligibilityResult result;
  final DateTime today;
  final VoidCallback onCompleteProfile;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canDonate = result.canDonate;
    final incomplete = result.status == EligibilityStatus.profileIncomplete;

    final background = incomplete
        ? scheme.surfaceContainerHighest
        : canDonate
        ? scheme.primaryContainer
        : scheme.secondaryContainer;
    final foreground = incomplete
        ? scheme.onSurface
        : canDonate
        ? scheme.onPrimaryContainer
        : scheme.onSecondaryContainer;

    final (icon, title, detail) = _texts();

    return Semantics(
      container: true,
      child: Card(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: foreground, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                detail,
                style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
              ),
              if (_progress case final value?) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  semanticsLabel: 'Progresso até a próxima doação',
                ),
              ],
              const SizedBox(height: 16),
              if (incomplete)
                FilledButton.tonalIcon(
                  onPressed: onCompleteProfile,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Completar perfil'),
                )
              else
                FilledButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar doação'),
                ),
              const SizedBox(height: 12),
              Text(
                'Estimativa educativa. A triagem clínica no hemocentro é quem '
                'confirma se você está apto.',
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? get _progress {
    final rules = result.rules;
    final last = result.lastDonation;
    final next = result.nextEligibleDate;
    if (rules == null || last == null || next == null) return null;
    final total = next.difference(last).inDays;
    if (total <= 0) return null;
    final remaining = result.daysRemaining(today);
    return ((total - remaining) / total).clamp(0.0, 1.0);
  }

  (IconData, String, String) _texts() {
    switch (result.status) {
      case EligibilityStatus.profileIncomplete:
        return (
          Icons.info_outline,
          'Complete seu perfil',
          'Informe seu sexo no perfil para calcularmos o intervalo entre '
              'doações (60 dias para homens, 90 para mulheres).',
        );
      case EligibilityStatus.noHistory:
        return (
          Icons.volunteer_activism,
          'Pronto para a primeira doação?',
          'Você ainda não registrou doações. Confira o guia e procure o '
              'hemocentro mais próximo.',
        );
      case EligibilityStatus.eligible:
        return (
          Icons.check_circle,
          'Você já pode doar',
          'Sua última doação foi em ${formatDate(result.lastDonation!)}. '
              'Doações nos últimos 12 meses: '
              '${result.donationsInLast12Months} de ${result.rules!.maxPerYear}.',
        );
      case EligibilityStatus.waitingInterval:
        final days = result.daysRemaining(today);
        return (
          Icons.hourglass_bottom,
          'Próxima doação em ${pluralDays(days)}',
          'A partir de ${formatLongDate(result.nextEligibleDate!)}, '
              'respeitando o intervalo mínimo de '
              '${result.rules!.minIntervalDays} dias.',
        );
      case EligibilityStatus.waitingYearlyLimit:
        final days = result.daysRemaining(today);
        return (
          Icons.event_busy,
          'Limite anual atingido',
          'Você fez ${result.donationsInLast12Months} doações nos últimos 12 '
              'meses (máximo ${result.rules!.maxPerYear}). Próxima doação em '
              '${pluralDays(days)}, a partir de '
              '${formatLongDate(result.nextEligibleDate!)}.',
        );
    }
  }
}
