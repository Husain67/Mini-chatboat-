import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import '../models/chat_session.dart';
import '../models/message.dart';
import '../services/openrouter_client.dart';
import '../state/app_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatView extends StatefulWidget {
  final ChatSession session;
  const ChatView({super.key, required this.session});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final OpenRouterClient _client = OpenRouterClient();
  bool _isTyping = false;
  bool _sendEnabled = false;
  stt.SpeechToText? _speech;
  bool _speechAvailable = false;
  bool _emojiVisible = false;
  final FocusNode _inputFocusNode = FocusNode();
    bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final s = stt.SpeechToText();
      final available = await s.initialize(
        onError: (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${e.errorMsg}')),
          );
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _isListening = status == 'listening';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _speech = s;
        _speechAvailable = available;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _speech?.cancel();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final app = context.read<AppState>();
    app.addMessage(text.trim(), isUser: true);
    _textController.clear();
    setState(() => _sendEnabled = false);
    _scrollToBottom();
    setState(() => _isTyping = true);
    try {
      final reply = await _client.generateReply(
        prompt: text.trim(),
        history: widget.session.messages,
      );
      app.addMessage(reply, isUser: false);
    } catch (e) {
      app.addMessage('Error: ${e.toString()}', isUser: false);
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(withReadStream: false);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        context.read<AppState>().addMessage(
              'File attached',
              isUser: true,
              attachmentUri: file.name,
            );
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attachment error: $e')));
    }
  }

  Future<void> _onMicPressed() async {
    if (_speech == null || !_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech not available')));
      return;
    }
    if (_isListening) {
      await _speech!.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    try {
      await _speech!.listen(onResult: (r) {
        if (!mounted) return;
        _textController.text = r.recognizedWords;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
        setState(() => _sendEnabled = _textController.text.trim().isNotEmpty);
      });
      if (mounted) setState(() => _isListening = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start listening: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = widget.session.messages;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: messages.length + 1 + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.t('today'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              final msgIndex = index - 1;
              if (msgIndex < messages.length) {
                final m = messages[msgIndex];
                return MessageBubble(
                  message: m,
                  onRegenerate: m.isUser ? null : () => _regenerateAt(msgIndex),
                  onLike: m.isUser
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thanks for the feedback (liked).')),
                          );
                        },
                  onDislike: m.isUser
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feedback received (disliked).')),
                          );
                        },
                  onShare: m.isUser
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: m.text));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message copied')),
                            );
                          }
                        },
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00D9FF), width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/icons/dreamflow_icon.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C3A4A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00D9FF), width: 2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('•', style: TextStyle(color: Colors.white, fontSize: 20)),
                            SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.white70, fontSize: 20)),
                            SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.white38, fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ChatInputBar(
          controller: _textController,
          onSend: _sendMessage,
          onAttachPressed: _pickAttachment,
          onMicPressed: _onMicPressed,
          onEmojiPressed: _toggleEmoji,
          focusNode: _inputFocusNode,
          onChanged: (v) => setState(() => _sendEnabled = v.trim().isNotEmpty),
          onTextFieldTap: () => setState(() => _emojiVisible = false),
          sendEnabled: _sendEnabled,
          isListening: _isListening,
        ),
        _buildEmojiPicker(),
      ],
    );
  }

  Future<void> _regenerateAt(int assistantIndex) async {
    final app = context.read<AppState>();
    final messages = widget.session.messages;
    if (assistantIndex < 0 || assistantIndex >= messages.length) return;
    // Find the nearest previous user message to use as the prompt
    int userIndex = -1;
    for (int i = assistantIndex - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        userIndex = i;
        break;
      }
    }
    if (userIndex == -1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user prompt to regenerate from.')));
      return;
    }

    final original = messages[assistantIndex];
    // Set placeholder while regenerating (keep timestamp)
    app.replaceMessageAt(
      assistantIndex,
      Message(text: 'Regenerating…', isUser: false, timestamp: original.timestamp, attachmentUri: original.attachmentUri),
    );

    try {
      final prompt = messages[userIndex].text;
      final history = messages.take(userIndex).toList();
      final reply = await _client.generateReply(prompt: prompt, history: history);
      // Replace with final reply
      app.replaceMessageAt(
        assistantIndex,
        Message(text: reply, isUser: false, timestamp: original.timestamp, attachmentUri: original.attachmentUri),
      );
      _scrollToBottom();
    } catch (e) {
      app.replaceMessageAt(
        assistantIndex,
        Message(text: 'Error regenerating: $e', isUser: false, timestamp: original.timestamp, attachmentUri: original.attachmentUri),
      );
    }
  }

  void _toggleEmoji() {
    setState(() {
      _emojiVisible = !_emojiVisible;
      if (_emojiVisible) {
        // Hide keyboard when showing emoji panel
        _inputFocusNode.unfocus();
      } else {
        // Bring back keyboard
        _inputFocusNode.requestFocus();
      }
    });
  }

  Widget _buildEmojiPicker() {
    if (!_emojiVisible) return const SizedBox.shrink();
    // Lazy import to keep file tidy
    return SizedBox(
      height: 280,
      child: _EmojiPickerArea(
        onEmoji: (emoji) {
          final text = _textController.text;
          final selection = _textController.selection;
          final start = selection.start >= 0 ? selection.start : text.length;
          final end = selection.end >= 0 ? selection.end : text.length;
          final newText = text.replaceRange(start, end, emoji);
          _textController.text = newText;
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: start + emoji.length));
          setState(() => _sendEnabled = _textController.text.trim().isNotEmpty);
        },
      ),
    );
  }
}

class _EmojiPickerArea extends StatelessWidget {
  final ValueChanged<String> onEmoji;
  const _EmojiPickerArea({required this.onEmoji});

  @override
  Widget build(BuildContext context) {
    // Configure a dark-themed emoji picker
    return ep.EmojiPicker(
      onEmojiSelected: (category, emoji) {
        onEmoji(emoji.emoji);
      },
      config: ep.Config(
        height: 280,
        checkPlatformCompatibility: true,
        emojiViewConfig: ep.EmojiViewConfig(
          backgroundColor: const Color(0xFF0A1929),
          emojiSizeMax: 28,
          noRecents: const Text('No Recents', style: TextStyle(color: Colors.white70)),
        ),
        categoryViewConfig: ep.CategoryViewConfig(
          backgroundColor: const Color(0xFF0E2230),
          iconColor: Colors.white54,
          iconColorSelected: const Color(0xFF00D9FF),
          indicatorColor: const Color(0xFF00D9FF),
        ),
        searchViewConfig: ep.SearchViewConfig(
          backgroundColor: const Color(0xFF1C3A4A),
          hintText: 'Search emoji',
          hintTextStyle: const TextStyle(color: Colors.white38),
        ),
        skinToneConfig: const ep.SkinToneConfig(),
      ),
    );
  }
}
