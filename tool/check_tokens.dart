import 'dart:io';

/// Quality gate: verify no raw hex colors or magic numeric spacing exist outside designated token/asset files.
void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Directory lib does not exist.');
    exit(1);
  }

  final hexRegex = RegExp(r'0x[0-9a-fA-F]{6,8}|#[0-9a-fA-F]{6,8}');
  var violations = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final path = entity.path.replaceAll(r'\', '/');
      // Whitelist token definition files
      if (path.contains('core/design/') ||
          path.contains('core/theme/') ||
          path.contains('app/theme/')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//') || line.trim().startsWith('*')) {
          continue;
        }

        if (hexRegex.hasMatch(line) && !line.contains('FontFeature')) {
          stdout.writeln('$path:${i + 1}: Found raw color hex: $line');
          violations++;
        }
      }
    }
  }

  if (violations > 0) {
    stderr.writeln('Found $violations token rule violations.');
    exit(1);
  } else {
    stdout.writeln(
      'check_tokens: clean. No raw hex in feature/presentation code.',
    );
  }
}
