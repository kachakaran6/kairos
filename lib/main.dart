import 'package:flutter/material.dart';

import 'app/shell/kairos_shell.dart';
import 'app/theme/kairos_theme_data.dart';

void main() {
  runApp(const KairosApp());
}

class KairosApp extends StatelessWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: KairosThemeData.light(),
      darkTheme: KairosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const KairosShell(),
    );
  }
}
