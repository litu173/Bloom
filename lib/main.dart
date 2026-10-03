import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_text.dart';
import 'screens/home_screen.dart';
import 'screens/ringing_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/success_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/bedtime_screen.dart';
import 'screens/wind_down_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  runApp(BloomAlarmApp(storage: storage));
}

class BloomAlarmApp extends StatelessWidget {
  final StorageService storage;
  const BloomAlarmApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(storage),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final colors = AppColors.of(state.isDark);
          return MaterialApp(
            title: 'Bloom Alarm',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(colors),
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

/// Shows the animated Bloom splash once at launch, then hands off to the
/// normal app shell. This is the *in-app* splash — see splash_screen.dart's
/// doc comment for how it relates to the minimal native launch screen.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: _showSplash
          ? SplashScreen(key: const ValueKey('splash'), onFinished: () => setState(() => _showSplash = false))
          : const AppShell(key: ValueKey('app')),
    );
  }
}

/// Mirrors App.tsx's `view` switch — a single-Scaffold shell that swaps the
/// visible screen based on AppState.view, with the alarm/challenge/success
/// flow layered on top of Home/Insights/Bedtime.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);

    Widget body;
    switch (state.view) {
      case AppView.home:
        body = const HomeScreen();
        break;
      case AppView.ringing:
        body = const RingingScreen();
        break;
      case AppView.challenge:
        body = const ChallengeScreen();
        break;
      case AppView.success:
        body = const SuccessScreen();
        break;
      case AppView.insights:
        body = const InsightsScreen();
        break;
      case AppView.bedtime:
        body = const BedtimeScreen();
        break;
      case AppView.windDown:
        body = const WindDownScreen();
        break;
    }

    return Scaffold(
      backgroundColor: c.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey(state.view), child: body),
      ),
    );
  }
}
