import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repositories.dart';
import '../../shared/widgets/common.dart';
import 'validators.dart';

/// Second step of password recovery: the user types the code received by
/// e-mail and chooses a new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthRepository>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.confirmPasswordReset(
        code: _code.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      showMessage(context, 'Senha redefinida. Entre com a nova senha.');
      context.go('/login');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: SingleChildScrollView(
        child: ResponsiveBody(
          maxWidth: 440,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.email == null
                      ? 'Digite o código enviado para seu e-mail e a nova senha.'
                      : 'Enviamos um código para ${widget.email}. Ele vale por '
                            '30 minutos.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  autocorrect: false,
                  validator: (v) => (v?.trim().length ?? 0) < 20
                      ? 'Cole o código completo recebido por e-mail.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    helperText: 'Mínimo de 8 caracteres',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Salvando…' : 'Redefinir senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
