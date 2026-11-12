import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../data/repositories/ai_repository.dart';
import '../../shared/widgets/common.dart';
import 'chat_view_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final ChatViewModel _chat;

  @override
  void initState() {
    super.initState();
    _chat = ChatViewModel(context.read<AiRepository>());
    _chat.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _chat.busy) return;
    _input.clear();
    await _chat.send(text);
  }

  @override
  void dispose() {
    _chat.removeListener(_changed);
    _chat.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = context.read<AppConfig>().isDemo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente de doação'),
        actions: [
          IconButton(
            tooltip: 'Nova conversa',
            onPressed: _chat.busy
                ? null
                : () {
                    _chat.clear();
                    _input.clear();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isDemo
          ? const MessageView(
              icon: Icons.chat_bubble_outline,
              title: 'Converse com o assistente',
              message: 'O chat com IA está disponível no modo API. Entre com sua conta para tirar dúvidas.',
            )
          : SafeArea(
              child: ResponsiveBody(
                maxWidth: 760,
                child: Column(
                  children: [
                    const Text(
                      'Respostas por IA podem conter erros. Não substituem avaliação profissional.',
                      style: TextStyle(fontSize: 12),
                    ),
                    Expanded(
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          if (_chat.messages.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Olá! Posso ajudar com dúvidas sobre doação e bancos de sangue.\n\n'
                                'As mensagens são enviadas ao Venice AI para responder. Evite compartilhar dados '
                                'pessoais ou de saúde. A conversa fica na memória durante esta sessão. '
                                'Use Nova conversa para apagá-la; sair da conta também limpa o chat.',
                              ),
                            ),
                          for (final message in _chat.messages)
                            _Bubble(
                              text: message.content,
                              user: message.role == 'user',
                            ),
                          if (_chat.pending != null)
                            _Bubble(text: _chat.pending!, user: true),
                          if (_chat.busy)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Preparando resposta…'),
                                ],
                              ),
                            ),
                          if (_chat.error != null)
                            Semantics(
                              liveRegion: true,
                              child: Column(
                                children: [
                                  Text(
                                    _chat.error!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _chat.send(_chat.pending!),
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_chat.busy)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final suggestion in _chat.suggestions)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 240,
                                      ),
                                      child: Text(
                                        suggestion,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onPressed: () => _send(suggestion),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            enabled: !_chat.busy,
                            minLines: 1,
                            maxLines: 3,
                            maxLength: 1000,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _send,
                            decoration: const InputDecoration(
                              labelText: 'Sua dúvida',
                              hintText: 'Pergunte sobre doação de sangue',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Enviar mensagem',
                          onPressed: _chat.busy
                              ? null
                              : () => _send(_input.text),
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.user});
  final String text;
  final bool user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: user
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user ? 'Você' : 'Assistente · IA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            SelectableText(text),
          ],
        ),
      ),
    );
  }
}
