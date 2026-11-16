import 'dart:io';

/// Quality gate: verify string hygiene and check for illegal hardcoded strings or debug residue.
void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Directory lib does not exist.');
    exit(1);
  }

  var violations = 0;
  final printRegex = RegExp(r'\bprint\s*\(');

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final path = entity.path.replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//')) continue;

        if (printRegex.hasMatch(line)) {
          stdout.writeln(
            '$path:${i + 1}: Found forbidden print() statement: $line',
          );
          violations++;
        }
      }
    }
  }

  if (violations > 0) {
    stderr.writeln('Found $violations string/debug violations.');
    exit(1);
  } else {
    stdout.writeln('check_strings: clean. No forbidden debug statements.');
  }
}
