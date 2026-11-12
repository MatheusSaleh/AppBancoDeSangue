class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatReply {
  const ChatReply({required this.reply, required this.suggestions});

  final String reply;
  final List<String> suggestions;
}
