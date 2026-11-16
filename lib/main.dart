import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/shell/kairos_shell.dart';
import 'app/theme/kairos_theme_data.dart';
import 'features/alarm/presentation/alarm_watcher.dart';
import 'features/settings/presentation/settings_controller.dart';

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

class _KairosAppContent extends ConsumerWidget {
  const _KairosAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final palette = settings.accentPalette;

    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: KairosThemeData.light(accentOverride: palette.lightColor),
      darkTheme: KairosThemeData.dark(accentOverride: palette.darkColor),
      themeMode: settings.themeMode,
      home: const AlarmWatcher(child: KairosShell()),
    );
  }
}
