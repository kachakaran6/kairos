import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../domain/user_settings.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: colours.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: kairos.typeScale.title.copyWith(color: colours.textPrimary),
        ),
        backgroundColor: colours.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colours.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.phoneMargin,
          vertical: Space.md,
        ),
        children: <Widget>[
          // Section: Appearance
          _SectionHeader(title: 'APPEARANCE'),
          _SettingsContainer(
            children: <Widget>[
              _TileRow(
                title: 'Theme Mode',
                subtitle: 'Match system, light or dark appearance',
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  dropdownColor: colours.surface,
                  style: TextStyle(color: colours.textPrimary),
                  underline: const SizedBox(),
                  onChanged: (mode) {
                    if (mode != null) controller.setThemeMode(mode);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _TileRow(
                title: 'Accent Palette',
                subtitle: 'Curated Apple-inspired brand accent',
                trailing: const SizedBox(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.md,
                ),
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: AccentPalette.values.map((p) {
                    final isSelected = settings.accentPalette == p;
                    final activeColor = colours.isDark
                        ? p.darkColor
                        : p.lightColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      onTap: () => controller.setAccentPalette(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.2)
                              : colours.surfaceElevated,
                          borderRadius: BorderRadius.circular(RadiusTokens.sm),
                          border: Border.all(
                            color: isSelected ? activeColor : colours.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: activeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: colours.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),

          // Section: Time & Date
          _SectionHeader(title: 'TIME & DATE'),
          _SettingsContainer(
            children: <Widget>[
              _SwitchRow(
                title: '24-Hour Time',
                subtitle: 'Use 23:08 instead of 11:08 PM',
                value: settings.use24HourFormat,
                onChanged: controller.set24HourFormat,
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'Show Seconds',
                subtitle: 'Live ticking seconds on clock header',
                value: settings.showSeconds,
                onChanged: controller.setShowSeconds,
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'Start Week on Monday',
                subtitle: 'Calendar and week calculation standard',
                value: settings.firstDayMonday,
                onChanged: controller.setFirstDayMonday,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),

          // Section: Notifications & Accessibility
          _SectionHeader(title: 'PREFERENCES & ACCESSIBILITY'),
          _SettingsContainer(
            children: <Widget>[
              _SwitchRow(
                title: 'Moment Reminders',
                subtitle: 'Local notification ladder before moments arrive',
                value: settings.notificationsEnabled,
                onChanged: controller.setNotificationsEnabled,
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'Reduce Motion',
                subtitle: 'Simpler, calmer interface transitions',
                value: settings.reduceMotion,
                onChanged: controller.setReduceMotion,
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'High Contrast Mode',
                subtitle: 'Enhanced text borders and separations',
                value: settings.highContrast,
                onChanged: controller.setHighContrast,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),

          // Section: Data & About
          _SectionHeader(title: 'DATA & ABOUT'),
          _SettingsContainer(
            children: <Widget>[
              _TileRow(
                title: 'Storage Architecture',
                subtitle: 'Local-first, encrypted offline SQLite',
                trailing: Text(
                  'Offline',
                  style: TextStyle(
                    color: colours.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              _TileRow(
                title: 'Version',
                subtitle: 'Kairos v1.0.0 (Production Release)',
                trailing: Text(
                  '1.0.0+1',
                  style: TextStyle(color: colours.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: Space.sm),
      child: Text(
        title,
        style: kairos.typeScale.section.copyWith(
          color: kairos.colours.textTertiary,
          letterSpacing: 0.6,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingsContainer extends StatelessWidget {
  const _SettingsContainer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colours = KairosTheme.of(context).colours;
    return Container(
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(color: colours.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colours.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: colours.textTertiary),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colours.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: colours.textTertiary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: colours.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
