import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/donation.dart';
import '../../domain/rules/donation_eligibility.dart';
import '../../shared/widgets/common.dart';
import 'donor_view_model.dart';

/// Creates or edits a donation. Unlike the 2023 form, the donor's name is
/// stored once in the profile instead of being typed on every record.
class DonationFormScreen extends StatefulWidget {
  const DonationFormScreen({super.key, this.donationId});

  final String? donationId;

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _location = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _date;
  Donation? _editing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final donor = context.read<DonorViewModel>();
    final id = widget.donationId;
    _editing = id == null ? null : donor.findById(id);
    final today = donor.today;
    _date = _editing?.date ?? DateTime(today.year, today.month, today.day);
    _location.text = _editing?.location ?? '';
    _notes.text = _editing?.notes ?? '';
  }

  @override
  void dispose() {
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = context.read<DonorViewModel>().today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Data da doação',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final donor = context.read<DonorViewModel>();
    final issue = donor.validateDate(_date, editingId: _editing?.id);
    if (issue == DonationDateIssue.inFuture ||
        issue == DonationDateIssue.tooOld) {
      showMessage(context, 'Escolha uma data válida que não esteja no futuro.');
      return;
    }
    if (issue == DonationDateIssue.tooCloseToAnother) {
      final proceed = await _confirmCloseDate();
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    try {
      await donor.saveDonation(
        Donation(
          id: _editing?.id ?? '',
          date: _date,
          location: _location.text.trim(),
          notes: _notes.text.trim(),
        ),
      );
      if (!mounted) return;
      showMessage(
        context,
        _editing == null
            ? 'Doação registrada. Obrigado!'
            : 'Registro atualizado.',
      );
      context.pop();
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmCloseDate() {
    final interval = context
        .read<DonorViewModel>()
        .eligibility
        .rules
        ?.minIntervalDays;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data muito próxima de outra doação'),
        content: Text(
          'Existe outro registro a menos de $interval dias desta data. '
          'Confira se a data está correta. Deseja salvar mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    if (widget.donationId != null && !isEditing) {
      return Scaffold(
        appBar: AppBar(),
        body: const MessageView(
          icon: Icons.search_off,
          title: 'Registro não encontrado',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar doação' : 'Registrar doação'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveBody(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Data da doação'),
                  subtitle: Text(formatLongDate(_date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Local (opcional)',
                  hintText: 'Ex.: Hemocentro Regional',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 280,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Salvando…' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
