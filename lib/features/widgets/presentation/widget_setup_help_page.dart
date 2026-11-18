import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';

/// In-app guide and direct system intent launcher for OEM background restrictions
/// (Xiaomi/HyperOS, Vivo, Oppo/Realme, Samsung, and Stock Android).
class WidgetSetupHelpPage extends StatefulWidget {
  const WidgetSetupHelpPage({super.key});

  @override
  State<WidgetSetupHelpPage> createState() => _WidgetSetupHelpPageState();
}

class _WidgetSetupHelpPageState extends State<WidgetSetupHelpPage> {
  static const MethodChannel _channel = MethodChannel(
    'com.samyukt.kairos/widget_oem',
  );

  String _manufacturer = 'detecting...';
  String _brand = '';
  String _model = '';
  int _sdk = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectDevice();
  }

  Future<void> _detectDevice() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'getManufacturer',
      );
      if (res != null && mounted) {
        setState(() {
          _manufacturer = res['manufacturer']?.toString() ?? 'unknown';
          _brand = res['brand']?.toString() ?? '';
          _model = res['model']?.toString() ?? '';
          _sdk = (res['sdk'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAutostart() async {
    HapticFeedback.lightImpact();
    try {
      await _channel.invokeMethod('openAutostartSettings');
    } catch (_) {
      _showToast('Unable to open Autostart settings directly.');
    }
  }

  Future<void> _openBattery() async {
    HapticFeedback.lightImpact();
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (_) {
      _showToast('Unable to open Battery settings directly.');
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  String get _oemTitle {
    final m = _manufacturer.toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return 'Xiaomi / HyperOS & MIUI';
    } else if (m.contains('vivo') || m.contains('iqoo')) {
      return 'Vivo / FuntouchOS & OriginOS';
    } else if (m.contains('oppo') ||
        m.contains('realme') ||
        m.contains('oneplus')) {
      return 'Oppo / Realme / OnePlus';
    } else if (m.contains('samsung')) {
      return 'Samsung / One UI';
    }
    return 'Android System';
  }

  List<String> get _oemInstructions {
    final m = _manufacturer.toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return [
        'Allow Autostart: Go to Apps > Permissions > Autostart and enable Kairos.',
        'Battery Saver: Select "No restrictions" so MIUI/HyperOS keeps widget data fresh.',
        'Lock in Recents: Open Recent Apps overview, press and hold Kairos, and tap the Lock icon.',
      ];
    } else if (m.contains('vivo') || m.contains('iqoo')) {
      return [
        'Autostart: Go to iManager > App Manager > Autostart and toggle Kairos ON.',
        'High Background Power: In Battery > Background power consumption, allow Kairos.',
        'Lock in Recents: In recent tasks view, swipe down on Kairos and tap the Padlock icon.',
      ];
    } else if (m.contains('oppo') ||
        m.contains('realme') ||
        m.contains('oneplus')) {
      return [
        'Auto-launch: Go to Settings > Apps > Auto-launch and allow Kairos.',
        'Battery Optimization: Set Battery Usage to "Allow background activity" and "Allow auto-launch".',
        'Lock in Recents: In app switcher, tap the three dots above Kairos and choose "Lock".',
      ];
    } else if (m.contains('samsung')) {
      return [
        'Never Sleeping Apps: In Device Care > Battery > Background usage limits, add Kairos to Never sleeping apps.',
        'Unrestricted Battery: Go to App Info > Battery and select "Unrestricted".',
        'Auto restart: Ensure widget update alarm permissions are granted.',
      ];
    }
    return [
      'Unrestricted Battery: Go to App Info > Battery and choose "Unrestricted".',
      'Alarm & Reminders: Ensure "Allow setting alarms and reminders" is granted.',
      'Allow Background Usage: Prevent system from putting Kairos to sleep.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return KairosScaffold(
      title: 'Widget Setup Help',
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Info Banner
            SurfaceCard(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colours.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: Icon(
                      LucideIcons.smartphone,
                      color: colours.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoading ? 'Detecting device...' : _oemTitle,
                          style: kairos.typeScale.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colours.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_brand $_model (Android SDK $_sdk)',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Space.lg),

            Text(
              '3 ESSENTIAL STEPS FOR RELIABLE WIDGETS',
              style: kairos.typeScale.label.copyWith(
                color: colours.textTertiary,
              ),
            ),
            const SizedBox(height: Space.sm),

            for (int i = 0; i < _oemInstructions.length; i++) ...[
              SurfaceCard(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colours.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: colours.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        _oemInstructions[i],
                        style: kairos.typeScale.body.copyWith(
                          color: colours.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
            ],

            const SizedBox(height: Space.lg),

            // Shortcut Buttons
            PillButton(
              onPressed: _openAutostart,
              label: 'Open Autostart Settings',
              icon: const Icon(LucideIcons.power, size: 18),
              variant: PillButtonVariant.primary,
            ),
            const SizedBox(height: Space.sm),
            PillButton(
              onPressed: _openBattery,
              label: 'Open Battery Settings (No Restrictions)',
              icon: const Icon(LucideIcons.batteryCharging, size: 18),
              variant: PillButtonVariant.secondary,
            ),
            const SizedBox(height: Space.huge),
          ],
        ),
      ),
    );
  }
}
