import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repositories.dart';
import '../../domain/models/blood_type.dart';
import '../../domain/models/donor_profile.dart';
import '../../shared/widgets/common.dart';
import '../auth/session_view_model.dart';
import '../donations/donor_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  BiologicalSex? _sex;
  BloodType? _bloodType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<DonorViewModel>().profile;
    _name = TextEditingController(text: profile.name);
    _sex = profile.sex;
    _bloodType = profile.bloodType;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<DonorViewModel>().saveProfile(
        DonorProfile(name: _name.text.trim(), sex: _sex, bloodType: _bloodType),
      );
      if (!mounted) return;
      showMessage(context, 'Perfil salvo.');
      context.pop();
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<SessionViewModel>().user?.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        child: ResponsiveBody(
          maxWidth: 560,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (email != null) ...[
                  Text(email, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Informe seu nome.' : null,
                ),
                const SizedBox(height: 24),
                Text('Sexo', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Usado apenas para aplicar o intervalo e o limite anual de '
                  'doações definidos pelo Ministério da Saúde.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<BiologicalSex>(
                  segments: [
                    for (final sex in BiologicalSex.values)
                      ButtonSegment(value: sex, label: Text(sex.label)),
                  ],
                  emptySelectionAllowed: true,
                  selected: {?_sex},
                  onSelectionChanged: (s) =>
                      setState(() => _sex = s.isEmpty ? null : s.first),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<BloodType?>(
                  initialValue: _bloodType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo sanguíneo (opcional)',
                    prefixIcon: Icon(Icons.bloodtype_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Não sei')),
                    for (final type in BloodType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (v) => setState(() => _bloodType = v),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvando…' : 'Salvar perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
