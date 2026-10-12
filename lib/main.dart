import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(GymApp(state: state));
}

class GymApp extends StatelessWidget {
  final AppState state;

  const GymApp({super.key, required this.state});

  ThemeData _theme(Brightness b) => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE4572E), brightness: b),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: b == Brightness.dark ? Colors.white12 : Colors.black12),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Find Your Gym Trainer',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: !state.onboarded
              ? const OnboardingScreen()
              : state.user == null
                  ? const AuthScreen()
                  : const Shell(),
        ),
      ),
    );
  }
}
