import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/models/blood_type.dart';
import '../../shared/widgets/common.dart';
import '../donations/donor_view_model.dart';

/// Red blood cell compatibility between ABO/Rh groups. Starts with the
/// donor's own blood type when it is known.
class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  late BloodType _selected;

  @override
  void initState() {
    super.initState();
    _selected =
        context.read<DonorViewModel>().profile.bloodType ?? BloodType.oNegative;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Compatibilidade sanguínea')),
      body: ResponsiveListView(
        children: [
          Text('Escolha um tipo sanguíneo', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in BloodType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: type == _selected,
                  onSelected: (_) => setState(() => _selected = type),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _GroupCard(
            icon: Icons.north_east,
            title: '${_selected.label} pode doar para',
            types: _selected.canDonateTo,
          ),
          const SizedBox(height: 12),
          _GroupCard(
            icon: Icons.south_west,
            title: '${_selected.label} pode receber de',
            types: _selected.canReceiveFrom,
          ),
          const SizedBox(height: 16),
          if (_selected == BloodType.oNegative)
            const DemoNotice(
              'O- é o doador universal de hemácias: por isso o estoque desse '
              'tipo é tão importante em emergências.',
              icon: Icons.lightbulb_outline,
            ),
          if (_selected == BloodType.abPositive)
            const DemoNotice(
              'AB+ é o receptor universal de hemácias.',
              icon: Icons.lightbulb_outline,
            ),
          const SizedBox(height: 16),
          Text(
            'Compatibilidade de concentrado de hemácias pelos sistemas ABO e '
            'Rh. Plasma e plaquetas seguem regras diferentes, e a transfusão '
            'sempre depende de exames de compatibilidade feitos pelo serviço '
            'de saúde.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.icon,
    required this.title,
    required this.types,
  });

  final IconData icon;
  final String title;
  final List<BloodType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in types)
                  Chip(
                    label: Text(t.label),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
