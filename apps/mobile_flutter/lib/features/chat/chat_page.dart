import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/repositories/chat_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/chat_components.dart';

class ChatPage extends StatefulWidget {
  ChatPage({
    super.key,
    required this.domain,
    ApiClient? apiClient,
    ChatRepository? repository,
  })  : apiClient = apiClient ?? ApiClient(),
        repository = repository ?? ApiChatRepository(apiClient: apiClient ?? ApiClient());

  final ApiClient apiClient;
  final ChatRepository repository;
  final Domain domain;

  @override
  State<ChatPage> createState() => _ChatPageState();
}


class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  String? _sessionId;
  String? _error;
  String? _lastSentText;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    _lastSentText = text;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _sending = true;
      _error = null;
    });
    _scrollToLatest();
    try {
      _sessionId ??= await widget.repository.createSession(widget.domain);
      final reply = await widget.repository.sendMessage(_sessionId!, text);
      if (mounted) {
        setState(() => _messages.add(reply));
        _scrollToLatest();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể gửi câu hỏi. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _retry() {
    final text = _lastSentText;
    if (text == null || _sending) return;
    if (_messages.isNotEmpty && _messages.last.isUser) {
      setState(() => _messages.removeLast());
    }
    _controller.text = text;
    _send();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hỏi AgriCare AI')),
    body: Column(
      children: [
        if (_sending) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _messages.isEmpty
              ? _EmptyChat(
                  onSuggestionSelected: (text) {
                    _controller
                      ..text = text
                      ..selection = TextSelection.collapsed(
                        offset: text.length,
                      );
                    FocusScope.of(context).unfocus();
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      ChatBubble(message: _messages[index]),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ),
                TextButton(onPressed: _retry, child: const Text('Thử lại')),
              ],
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      labelText: 'Nhập câu hỏi',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  tooltip: 'Gửi câu hỏi',
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestionSelected});
  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Hãy hỏi về cây trồng hoặc vật nuôi của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: ['Lá cây bị vàng phải làm sao?', 'Cách phòng sâu bệnh?']
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestionSelected(suggestion),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}
