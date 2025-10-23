import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';
import '../models/message.dart';

class AppState extends ChangeNotifier {
  static const _prefsKey = 'chat_sessions_v1';
  static const _prefsThemeMode = 'theme_mode_v1';
  static const _prefsEyeMode = 'eye_mode_v1';
  static const _prefsLocale = 'locale_v1';

  final List<ChatSession> _sessions = [];
  int _currentIndex = 0;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _eyeMode = false;
  Locale _locale = const Locale('en');

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  int get currentIndex => _currentIndex;
  ThemeMode get themeMode => _themeMode;
  bool get eyeMode => _eyeMode;
  Locale get locale => _locale;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Sessions
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = (jsonDecode(raw) as List<dynamic>)
              .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
              .toList();
          _sessions
            ..clear()
            ..addAll(list);
        } catch (_) {}
      }
      if (_sessions.isEmpty) {
        _sessions.add(
          ChatSession(id: _newId(), title: 'Chat 1', messages: [
            Message(text: 'Hello! How can I help you today?', isUser: false, timestamp: _timeNow()),
          ]),
        );
      }

      // Theme
      final mode = prefs.getString(_prefsThemeMode);
      if (mode == 'light') _themeMode = ThemeMode.light;
      if (mode == 'dark') _themeMode = ThemeMode.dark;
      if (mode == 'system') _themeMode = ThemeMode.system;

      // Eye mode
      _eyeMode = prefs.getBool(_prefsEyeMode) ?? false;

      // Locale
      final loc = prefs.getString(_prefsLocale);
      if (loc == 'hi') _locale = const Locale('hi');
    } catch (e) {
      // Fallback: if preferences are unavailable (e.g., web plugin not registered),
      // initialize defaults with an initial chat and continue.
      if (_sessions.isEmpty) {
        _sessions.add(
          ChatSession(id: _newId(), title: 'Chat 1', messages: [
            Message(text: 'Hello! How can I help you today?', isUser: false, timestamp: _timeNow()),
          ]),
        );
      }
      // No persistence in this mode.
      // ignore: avoid_print
      print('SharedPreferences unavailable, running without persistence: $e');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_sessions.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Persist skipped (prefs unavailable): $e');
    }
  }

  Future<void> _persistTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = _themeMode == ThemeMode.light
          ? 'light'
          : _themeMode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await prefs.setString(_prefsThemeMode, value);
    } catch (e) {
      // ignore: avoid_print
      print('Persist theme skipped (prefs unavailable): $e');
    }
  }

  Future<void> _persistEye() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsEyeMode, _eyeMode);
    } catch (e) {
      // ignore: avoid_print
      print('Persist eye mode skipped (prefs unavailable): $e');
    }
  }

  Future<void> _persistLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLocale, _locale.languageCode);
    } catch (e) {
      // ignore: avoid_print
      print('Persist locale skipped (prefs unavailable): $e');
    }
  }

  void switchTo(int index) {
    if (index < 0 || index >= _sessions.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  void newChat() {
    final id = _newId();
    final title = 'Chat ${_sessions.length + 1}';
    _sessions.add(ChatSession(id: id, title: title, messages: [
      Message(text: 'New chat started. Ask me anything!', isUser: false, timestamp: _timeNow()),
    ]));
    _currentIndex = _sessions.length - 1;
    _persist();
    notifyListeners();
  }

  void clearCurrentChat() {
    final s = _sessions[_currentIndex];
    s.messages.clear();
    s.messages.add(Message(text: 'Welcome back! How can I assist?', isUser: false, timestamp: _timeNow()));
    _persist();
    notifyListeners();
  }

  void addMessage(String text, {required bool isUser, String? attachmentUri}) {
    final s = _sessions[_currentIndex];
    s.messages.add(Message(text: text, isUser: isUser, timestamp: _timeNow(), attachmentUri: attachmentUri));
    _persist();
    notifyListeners();
  }

  /// Replace a message at the given index in the current session and persist.
  void replaceMessageAt(int index, Message message) {
    final s = _sessions[_currentIndex];
    if (index < 0 || index >= s.messages.length) return;
    s.messages[index] = message;
    _persist();
    notifyListeners();
  }

  /// Remove a message at the given index in the current session and persist.
  void removeMessageAt(int index) {
    final s = _sessions[_currentIndex];
    if (index < 0 || index >= s.messages.length) return;
    s.messages.removeAt(index);
    _persist();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _persistTheme();
    notifyListeners();
  }

  void toggleEyeMode() {
    _eyeMode = !_eyeMode;
    _persistEye();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _persistLocale();
    notifyListeners();
  }

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();
  String _timeNow() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
