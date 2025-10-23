import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatmate/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onShare;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onLike,
    this.onDislike,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/icons/dreamflow_icon.jpg'),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: message.isUser ? const Color(0xFF2C4A5A) : const Color(0xFF1C3A4A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: message.isUser ? Colors.transparent : const Color(0xFF00D9FF),
                      width: message.isUser ? 0 : 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.attachmentUri != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'File: ${message.attachmentUri}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      ..._buildMessageSegments(context, message.text),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    message.timestamp,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (!message.isUser) ...[
                  const SizedBox(height: 6),
                  _ActionBar(
                    onRegenerate: onRegenerate,
                    onLike: onLike,
                    onDislike: onDislike,
                    onShare: onShare,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessageSegments(BuildContext context, String text) {
    final theme = Theme.of(context);
    final codeRegex = RegExp(r"```([a-zA-Z0-9_+-]*)\n([\s\S]*?)```", multiLine: true);
    final widgets = <Widget>[];
    int lastIndex = 0;
    for (final match in codeRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final plain = text.substring(lastIndex, match.start).trim();
        if (plain.isNotEmpty) {
          widgets.add(
            Text(
              plain,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 12));
        }
      }
      final lang = (match.group(1) ?? '').trim();
      final code = (match.group(2) ?? '').trimRight();
      widgets.add(_CodeBox(language: lang, code: code));
      widgets.add(const SizedBox(height: 12));
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      final tail = text.substring(lastIndex).trim();
      if (tail.isNotEmpty) {
        widgets.add(
          Text(
            tail,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
        );
      }
    }
    if (widgets.isEmpty) {
      widgets.add(
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    return widgets;
  }
}

class _CodeBox extends StatelessWidget {
  final String language;
  final String code;
  const _CodeBox({required this.language, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0E2230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D9FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF123447),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isNotEmpty ? language : 'code',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                  label: const Text('Copy', style: TextStyle(color: Colors.white70)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    foregroundColor: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback? onRegenerate;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onShare;
  const _ActionBar({this.onRegenerate, this.onLike, this.onDislike, this.onShare});

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.7);
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: [
        TextButton.icon(
          onPressed: onRegenerate,
          icon: Icon(Icons.refresh, size: 18, color: color),
          label: Text('Regenerate', style: TextStyle(color: color, fontSize: 13)),
        ),
        TextButton.icon(
          onPressed: onLike,
          icon: Icon(Icons.thumb_up_alt_outlined, size: 18, color: color),
          label: Text('Like', style: TextStyle(color: color, fontSize: 13)),
        ),
        TextButton.icon(
          onPressed: onDislike,
          icon: Icon(Icons.thumb_down_alt_outlined, size: 18, color: color),
          label: Text('Dislike', style: TextStyle(color: color, fontSize: 13)),
        ),
        TextButton.icon(
          onPressed: onShare,
          icon: Icon(Icons.share_outlined, size: 18, color: color),
          label: Text('Share', style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }
}
