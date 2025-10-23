import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chatmate/theme.dart';
import 'package:chatmate/screens/chat_screen.dart';
import 'package:chatmate/state/app_state.dart';
import 'package:chatmate/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1C3A4A),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A1929),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap({super.key});

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      // Delay loading persisted state until after first frame to ensure
      // plugins (e.g., shared_preferences) are fully registered on web.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AppState>().load();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final filter = app.eyeMode
            ? _warmFilter()
            : const ColorFilter.matrix(<double>[
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                0, 0, 0, 1, 0,
              ]);
        return ColorFiltered(
          colorFilter: filter,
          child: MaterialApp(
            title: 'AI Chatbot',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: app.themeMode,
            locale: app.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ChatScreen(),
          ),
        );
      },
    );
  }
}

ColorFilter _warmFilter() {
  // Simple yellowish warm matrix to reduce blue light
  const r = 1.0;
  const g = 0.9;
  const b = 0.75; // reduce blue
  return const ColorFilter.matrix(<double>[
    r, 0, 0, 0, 0,
    0, g, 0, 0, 0,
    0, 0, b, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}
