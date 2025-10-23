import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:chatmate/models/message.dart';
import 'package:chatmate/secrets.dart';

class OpenRouterClient {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  final http.Client _httpClient;

  OpenRouterClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Future<String> generateReply({required String prompt, required List<Message> history}) async {
    // Build messages history for OpenAI-compatible schema
    final List<Map<String, String>> messages = [];

    // Optional system prompt to keep tone helpful
    messages.add({
      'role': 'system',
      'content': 'You are a helpful, concise AI assistant.'
    });

    for (final m in history) {
      messages.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }

    // Append the latest user prompt (not yet in history when called)
    messages.add({'role': 'user', 'content': prompt});

    final body = jsonEncode({
      'model': openRouterModel,
      'messages': messages,
      // Reasonable defaults
      'temperature': 0.7,
      'max_tokens': 512,
    });

    final response = await _httpClient.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $openRouterApiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices.first['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) return content.trim();
      }
      throw Exception('OpenRouter: empty response');
    } else {
      // Try to parse error details
      try {
        final err = jsonDecode(response.body);
        throw Exception('OpenRouter error ${response.statusCode}: ${err.toString()}');
      } catch (_) {
        throw Exception('OpenRouter error ${response.statusCode}: ${response.body}');
      }
    }
  }
}
