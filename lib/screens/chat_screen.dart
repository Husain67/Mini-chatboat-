import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../widgets/chat_view.dart';
import '../l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  void _syncController() {
    final app = context.read<AppState>();
    final len = app.sessions.length;
    if (_tabController == null || _tabController!.length != len) {
      _tabController?.dispose();
      _tabController = TabController(length: len, vsync: this, initialIndex: app.currentIndex);
      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) return;
        app.switchTo(_tabController!.index);
      });
    } else if (_tabController!.index != app.currentIndex) {
      _tabController!.animateTo(app.currentIndex);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);
    _syncController();

    if (app.sessions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1929),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C3A4A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        // Title intentionally removed as requested (no name/logo in headline)
        title: const SizedBox.shrink(),
        centerTitle: true,
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenu(value),
            itemBuilder: (context) => [
              PopupMenuItem(value: _MenuAction.history, child: Text(l10n.t('history'))),
              PopupMenuItem(value: _MenuAction.newChat, child: Text(l10n.t('new_chat'))),
              const PopupMenuDivider(),
              PopupMenuItem(value: _MenuAction.about, child: Text(l10n.t('about'))),
              PopupMenuItem(value: _MenuAction.privacy, child: Text(l10n.t('privacy_policy'))),
              PopupMenuItem(value: _MenuAction.language, child: Text(l10n.t('app_language'))),
              PopupMenuItem(value: _MenuAction.version, child: Text(l10n.t('app_version'))),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: _MenuAction.darkMode,
                checked: app.themeMode == ThemeMode.dark,
                child: Text(l10n.t('dark_mode')),
              ),
              CheckedPopupMenuItem(
                value: _MenuAction.eyeMode,
                checked: app.eyeMode,
                child: Text(l10n.t('eye_mode')),
              ),
              CheckedPopupMenuItem(
                value: _MenuAction.systemMode,
                checked: app.themeMode == ThemeMode.system,
                child: Text(l10n.t('system_mode')),
              ),
            ],
          ),
        ],
        bottom: app.sessions.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  for (final s in app.sessions)
                    Tab(text: s.title),
                ],
              )
            : null,
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final s in app.sessions) ChatView(session: s),
        ],
      ),
    );
  }

  void _handleMenu(_MenuAction action) async {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _MenuAction.history:
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF0E2230),
          showDragHandle: true,
          builder: (context) {
            return ListView.builder(
              itemCount: app.sessions.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.history, color: Colors.white70),
                title: Text(app.sessions[i].title, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  app.switchTo(i);
                },
              ),
            );
          },
        );
        break;
      case _MenuAction.newChat:
        app.newChat();
        break;
      case _MenuAction.about:
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.t('about')),
            content: const Text('VokAI v1.0.0\nA simple AI chat app.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.t('ok')))],
          ),
        );
        break;
      case _MenuAction.privacy:
        final uri = Uri.parse('https://example.com/privacy');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
      case _MenuAction.language:
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF0E2230),
          showDragHandle: true,
          builder: (context) {
            final isHindi = app.locale.languageCode == 'hi';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                  value: false,
                  groupValue: isHindi,
                  onChanged: (_) {
                    app.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                  title: Text(l10n.t('english'), style: const TextStyle(color: Colors.white)),
                ),
                RadioListTile<bool>(
                  value: true,
                  groupValue: isHindi,
                  onChanged: (_) {
                    app.setLocale(const Locale('hi'));
                    Navigator.pop(context);
                  },
                  title: Text(l10n.t('hindi'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
        break;
      case _MenuAction.version:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('version_value'))));
        break;
      case _MenuAction.darkMode:
        app.setThemeMode(ThemeMode.dark);
        break;
      case _MenuAction.eyeMode:
        app.toggleEyeMode();
        break;
      case _MenuAction.systemMode:
        app.setThemeMode(ThemeMode.system);
        break;
    }
  }
}

enum _MenuAction { history, newChat, about, privacy, language, version, darkMode, eyeMode, systemMode }

// Removed unused _Dot widget and its optional parameter 'delay' that was never used.
