import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app/shell/kairos_shell.dart';
import 'app/theme/kairos_theme_data.dart';
import 'core/ecosystem/play_update_service.dart';
import 'features/alarm/presentation/alarm_page.dart';
import 'features/alarm/presentation/alarm_watcher.dart';
import 'features/focus/presentation/focus_page.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/world_clock/presentation/world_clock_page.dart';

void main() {
  runApp(const KairosApp());
}

class KairosApp extends StatelessWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _KairosAppContent());
  }
}

class _KairosAppContent extends ConsumerStatefulWidget {
  const _KairosAppContent();

  @override
  ConsumerState<_KairosAppContent> createState() => _KairosAppContentState();
}

class _KairosAppContentState extends ConsumerState<_KairosAppContent> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int _tabIndex = 1;

  @override
  void initState() {
    super.initState();
    _initHomeWidgetListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(playUpdateServiceProvider)
          .checkAndPromptUpdate(isAutomatic: true);
    });
  }

  void _initHomeWidgetListener() {
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      HomeWidget.widgetClicked.listen(_handleWidgetUri);
    } catch (_) {
      // Safe fallback in test harnesses
    }
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final path = '${uri.host}${uri.path}';

    if (path.contains('next')) {
      setState(() => _tabIndex = 0);
    } else if (path.contains('then')) {
      setState(() => _tabIndex = 2);
    } else if (path.contains('now')) {
      setState(() => _tabIndex = 1);
    } else if (path.contains('world_clock')) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const WorldClockPage()),
      );
    } else if (path.contains('alarm')) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const AlarmPage()),
      );
    } else if (path.contains('focus')) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const FocusPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final palette = settings.accentPalette;

    return MaterialApp(
      title: 'Kairos',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: KairosThemeData.light(accentOverride: palette.lightColor),
      darkTheme: KairosThemeData.dark(accentOverride: palette.darkColor),
      themeMode: settings.themeMode,
      home: AlarmWatcher(
        child: KairosShell(
          key: ValueKey<int>(_tabIndex),
          initialIndex: _tabIndex,
        ),
      ),
    );
  }
}
