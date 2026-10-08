/// A quick-reply chip under an assistant message.
/// [kind] is 'choice' (sent to the server), 'message' (label sent as text),
/// 'upload' / 'preview' (handled in the app) or 'retry' (local, after a failed send).
class ChatOption {
  final String id;
  final String label;
  final String kind;

  const ChatOption({required this.id, required this.label, this.kind = 'choice'});

  factory ChatOption.fromJson(Map<String, dynamic> j) => ChatOption(
        id: j['id']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'choice',
      );
}

/// One chat bubble. [type] is 'text', 'file', 'data_card', 'upload_card' or 'ready_card'.
class ChatMessage {
  final String role;
  final String type;
  final String text;
  final List<ChatOption> options;
  final Map<String, dynamic>? data;

  const ChatMessage({
    required this.role,
    this.type = 'text',
    this.text = '',
    this.options = const [],
    this.data,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role']?.toString() ?? 'assistant',
        type: j['type']?.toString() ?? 'text',
        text: j['text']?.toString() ?? '',
        options: (j['options'] as List? ?? [])
            .whereType<Map>()
            .map((o) => ChatOption.fromJson(Map<String, dynamic>.from(o)))
            .toList(),
        data: j['data'] is Map ? Map<String, dynamic>.from(j['data']) : null,
      );
}
