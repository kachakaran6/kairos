import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/widget_suite/widget_config.dart';
import '../domain/widget_look.dart';

/// Manages built-in and user-saved custom Looks for Kairos Home Widgets.
class LookPresetsManager {
  static const String _customLooksKey = 'kairos_custom_widget_looks';

  /// Returns all available Looks (10 built-in + user-saved).
  static Future<List<WidgetLook>> loadAllLooks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_customLooksKey);
    final list = <WidgetLook>[...WidgetLook.all];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in decoded) {
          final m = item as Map<String, dynamic>;
          list.add(
            WidgetLook(
              id: m['id'] as String,
              name: m['name'] as String,
              description: m['description'] as String? ?? 'Custom saved Look',
              backgroundColor: Color(
                int.parse(
                  (m['backgroundColor'] as String).replaceFirst('#', '0xFF'),
                ),
              ),
              surfaceColor: Color(
                int.parse(
                  (m['surfaceColor'] as String).replaceFirst('#', '0xFF'),
                ),
              ),
              accentColor: Color(
                int.parse(
                  (m['accentColor'] as String).replaceFirst('#', '0xFF'),
                ),
              ),
              primaryTextColor: Color(
                int.parse(
                  (m['primaryTextColor'] as String).replaceFirst('#', '0xFF'),
                ),
              ),
              secondaryTextColor: Color(
                int.parse(
                  (m['secondaryTextColor'] as String).replaceFirst('#', '0xFF'),
                ),
              ),
              borderColor: Color(
                int.parse(
                  (m['borderColor'] as String).replaceFirst('#', '0xFF'),
                ),
              ),
              isDark: m['isDark'] as bool? ?? true,
            ),
          );
        }
      } catch (_) {}
    }
    return list;
  }

  /// Saves a custom Look generated from the current widget studio configuration.
  static Future<WidgetLook> saveCustomLook({
    required String name,
    required WidgetConfig config,
  }) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final isDark = config.themeMode == 'dark';

    Color parseHex(String hex, Color fallback) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {
        return fallback;
      }
    }

    final accent = parseHex(config.accentHex, const Color(0xFFE8895A));
    final text = parseHex(
      config.textColor,
      isDark ? const Color(0xFFF4EFE8) : const Color(0xFF14120E),
    );
    final textSec = parseHex(
      config.textSecondaryColor,
      isDark ? const Color(0xFF9E968D) : const Color(0xFF68625B),
    );
    final bg = parseHex(
      config.backgroundColor,
      isDark ? const Color(0xFF0F0D0B) : const Color(0xFFFAF7F2),
    );

    final newLook = WidgetLook(
      id: id,
      name: name,
      description: 'Personalized user Look',
      backgroundColor: bg,
      surfaceColor: bg,
      accentColor: accent,
      primaryTextColor: text,
      secondaryTextColor: textSec,
      borderColor: accent.withValues(alpha: 0.3),
      isDark: isDark,
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_customLooksKey);
    final list = <Map<String, dynamic>>[];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        list.addAll(decoded.cast<Map<String, dynamic>>());
      } catch (_) {}
    }

    String colorToHex(Color c) {
      final val = c.toARGB32();
      return '#${val.toRadixString(16).padLeft(8, '0').substring(2)}';
    }

    list.add({
      'id': id,
      'name': name,
      'description': 'Personalized user Look',
      'backgroundColor': colorToHex(bg),
      'surfaceColor': colorToHex(bg),
      'accentColor': colorToHex(accent),
      'primaryTextColor': colorToHex(text),
      'secondaryTextColor': colorToHex(textSec),
      'borderColor': colorToHex(accent.withValues(alpha: 0.3)),
      'isDark': isDark,
    });

    await prefs.setString(_customLooksKey, jsonEncode(list));
    return newLook;
  }

  /// Exports a WidgetConfig to an easily shareable short string / JSON.
  static String exportConfig(WidgetConfig config) {
    final raw = jsonEncode(config.toJson());
    return base64Url.encode(utf8.encode(raw));
  }

  /// Imports a WidgetConfig from an exported base64 code or JSON string.
  static WidgetConfig? importConfig(String code) {
    try {
      final trimmed = code.trim();
      String jsonStr;
      if (trimmed.startsWith('{')) {
        jsonStr = trimmed;
      } else {
        jsonStr = utf8.decode(base64Url.decode(trimmed));
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WidgetConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a custom Look by ID.
  static Future<void> deleteCustomLook(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_customLooksKey);
    if (jsonStr == null || jsonStr.isEmpty) return;
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      final updated = decoded
          .where((item) => (item as Map)['id'] != id)
          .toList();
      await prefs.setString(_customLooksKey, jsonEncode(updated));
    } catch (_) {}
  }
}
