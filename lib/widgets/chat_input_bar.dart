import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onAttachPressed;
  final VoidCallback onEmojiPressed;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTextFieldTap;
  final bool sendEnabled;
  final bool isListening;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMicPressed,
    required this.onAttachPressed,
    required this.onEmojiPressed,
    required this.focusNode,
    this.onChanged,
    this.onTextFieldTap,
    this.sendEnabled = false,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white54, size: 26),
              onPressed: onEmojiPressed,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white54, size: 26),
              onPressed: onAttachPressed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C3A4A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                  onTap: onTextFieldTap,
                  onSubmitted: (text) => onSend(text),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? const Color(0xFF00D9FF) : Colors.white54,
                size: 26,
              ),
              onPressed: onMicPressed,
              tooltip: isListening ? 'Stop listening' : 'Start voice input',
            ),
            const SizedBox(width: 4),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF00D9FF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF0A1929), size: 22),
                onPressed: sendEnabled ? () => onSend(controller.text) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
