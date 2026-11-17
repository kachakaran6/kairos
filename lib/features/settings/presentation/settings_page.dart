import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/ecosystem/app_version_service.dart';
import '../../../core/ecosystem/play_review_service.dart';
import '../../../core/ecosystem/play_update_service.dart';
import '../../../core/ecosystem/samyukt_share_service.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/kairos_segmented_control.dart';
import '../../../core/widgets/surface_card.dart';
import '../../ecosystem/presentation/our_apps_page.dart';
import '../../widgets/presentation/widget_studio_page.dart';
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

    return KairosScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.phoneMargin,
          vertical: Space.md,
        ),
        children: <Widget>[
          // Section: Appearance
          _SectionHeader(title: 'APPEARANCE'),
          SurfaceCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Theme Mode',
                  style: kairos.typeScale.body.copyWith(
                    color: colours.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose between daylight paper or warm obsidian dark.',
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
                const SizedBox(height: Space.md),
                KairosSegmentedControl<ThemeMode>(
                  selected: settings.themeMode,
                  onChanged: (mode) => controller.setThemeMode(mode),
                  items: const {
                    ThemeMode.system: 'System',
                    ThemeMode.light: 'Light',
                    ThemeMode.dark: 'Dark',
                  },
                ),
                const SizedBox(height: Space.lg),
                Divider(color: colours.border, height: 1),
                const SizedBox(height: Space.lg),
                Text(
                  'Accent Palette',
                  style: kairos.typeScale.body.copyWith(
                    color: colours.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Curated precision color themes inspired by horology.',
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.md,
                  runSpacing: Space.md,
                  alignment: WrapAlignment.spaceAround,
                  children: AccentPalette.values.map((p) {
                    final isSelected = settings.accentPalette == p;
                    final activeColor = colours.isDark
                        ? p.darkColor
                        : p.lightColor;

                    return GestureDetector(
                      onTap: () => controller.setAccentPalette(p),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor,
                              border: Border.all(
                                color: isSelected
                                    ? colours.textPrimary
                                    : colours.border,
                                width: isSelected ? 2.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: activeColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      LucideIcons.check,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.label,
                            style: kairos.typeScale.caption.copyWith(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? colours.textPrimary
                                  : colours.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),

          // Section: Time & Precision
          _SectionHeader(title: 'TIME & PRECISION'),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _SettingSwitchTile(
                  icon: LucideIcons.clock,
                  title: '24-Hour Time',
                  subtitle: 'Display time in 00:00 - 23:59 military format',
                  value: settings.use24HourFormat,
                  onChanged: (val) => controller.set24HourFormat(val),
                ),
                Divider(color: colours.border, height: 1, indent: 56),
                _SettingSwitchTile(
                  icon: LucideIcons.timer,
                  title: 'Show Seconds',
                  subtitle: 'Live sweeping seconds counter in clocks and cards',
                  value: settings.showSeconds,
                  onChanged: (val) => controller.setShowSeconds(val),
                ),
                Divider(color: colours.border, height: 1, indent: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colours.accentMuted,
                        ),
                        child: Icon(
                          LucideIcons.hash,
                          size: 18,
                          color: colours.accent,
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tabular Numerals',
                              style: kairos.typeScale.body.copyWith(
                                color: colours.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Equal glyph widths guarantee zero jitter as numbers tick',
                              style: kairos.typeScale.caption.copyWith(
                                color: colours.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colours.accentMuted,
                          borderRadius: RadiusTokens.pillRadius,
                        ),
                        child: Text(
                          'ALWAYS ON',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),

          // Section: Calendar & Accessibility
          _SectionHeader(title: 'CALENDAR & ACCESSIBILITY'),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _SettingSwitchTile(
                  icon: LucideIcons.calendar,
                  title: 'Start Week on Monday',
                  subtitle: 'Align week grids with ISO 8601 standard',
                  value: settings.firstDayMonday,
                  onChanged: (val) => controller.setFirstDayMonday(val),
                ),
                Divider(color: colours.border, height: 1, indent: 56),
                _SettingSwitchTile(
                  icon: LucideIcons.move,
                  title: 'Reduce Motion',
                  subtitle: 'Minimize animations and particle bursts',
                  value: settings.reduceMotion,
                  onChanged: (val) => controller.setReduceMotion(val),
                ),
                Divider(color: colours.border, height: 1, indent: 56),
                _SettingSwitchTile(
                  icon: LucideIcons.contrast,
                  title: 'High Contrast Mode',
                  subtitle: 'Boost border contrast and text definition',
                  value: settings.highContrast,
                  onChanged: (val) => controller.setHighContrast(val),
                ),
                Divider(color: colours.border, height: 1, indent: 56),
                _SettingSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Moment Reminders',
                  subtitle: 'Local alerts at target time and zero moments',
                  value: settings.notificationsEnabled,
                  onChanged: (val) => controller.setNotificationsEnabled(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),

          // Section: Privacy & Local Architecture
          _SectionHeader(title: 'LOCAL-FIRST ARCHITECTURE'),
          SurfaceCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colours.accentMuted,
                  ),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 22,
                    color: colours.accent,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: kairos.typeScale.body.copyWith(
                          color: colours.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No trackers, no cloud sync, and no third-party telemetry. All moments and alarms stay on your device.',
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

          const SizedBox(height: Space.xl),

          // Section: Home Screen Widgets
          _SectionHeader(title: 'HOME SCREEN WIDGETS'),
          SurfaceCard(
            padding: const EdgeInsets.all(Space.lg),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WidgetStudioPage(),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colours.accentMuted,
                    ),
                    child: Icon(
                      LucideIcons.layoutGrid,
                      size: 22,
                      color: colours.accent,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Widget Studio',
                          style: kairos.typeScale.body.copyWith(
                            color: colours.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tailor clock, countdown, world clock and combo widgets with 6 luxury looks.',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colours.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Space.xl),

          // Samyukt Ecosystem
          _SectionHeader(title: 'SAMYUKT ECOSYSTEM'),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                _ActionTile(
                  icon: LucideIcons.layoutGrid,
                  title: 'Our Apps',
                  subtitle: 'Explore mobile applications by Samyukt',
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colours.textTertiary,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OurAppsPage(),
                      ),
                    );
                  },
                ),
                Divider(color: colours.border, height: 1),
                _ActionTile(
                  icon: LucideIcons.downloadCloud,
                  title: 'Check for Updates',
                  subtitle: 'Google Play official update service',
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Checking Google Play for updates...',
                        ),
                        backgroundColor: colours.surface,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    final hasUpdate = await ref
                        .read(playUpdateServiceProvider)
                        .checkAndPromptUpdate(isAutomatic: false);
                    if (!hasUpdate && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Kairos is up to date.'),
                          backgroundColor: colours.surface,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
                Divider(color: colours.border, height: 1),
                _ActionTile(
                  icon: LucideIcons.star,
                  title: 'Rate Kairos',
                  subtitle: 'Review on Google Play Store',
                  trailing: Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: colours.textTertiary,
                  ),
                  onTap: () => ref.read(playReviewServiceProvider).rateNow(),
                ),
                Divider(color: colours.border, height: 1),
                _ActionTile(
                  icon: LucideIcons.share2,
                  title: 'Share Kairos',
                  subtitle: 'Share with friends and colleagues',
                  trailing: Icon(
                    LucideIcons.arrowUpRight,
                    size: 16,
                    color: colours.textTertiary,
                  ),
                  onTap: () =>
                      ref.read(samyuktShareServiceProvider).shareApplication(),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),

          // About
          _SectionHeader(title: 'ABOUT KAIROS'),
          SurfaceCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colours.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.hourglass,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kairos Chronometer',
                            style: kairos.typeScale.body.copyWith(
                              color: colours.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          FutureBuilder<AppVersionMetadata>(
                            future: ref
                                .read(appVersionServiceProvider)
                                .getVersionMetadata(),
                            builder: (context, snapshot) {
                              final versionStr =
                                  snapshot.data?.formattedVersion ??
                                  'Version 1.0.0 (Build 1)';
                              return Text(
                                versionStr,
                                style: kairos.typeScale.caption.copyWith(
                                  color: colours.textSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Text(
                  'Designed with Warm Precision. Every instant counted with Swiss precision and calm intent.',
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),

          // Samyukt Attribution Footer
          Center(
            child: GestureDetector(
              onTap: () => ref
                  .read(playServicesBridgeProvider)
                  .openUrl('https://samyukt.pro'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Made with care by ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: colours.textSecondary,
                      ),
                    ),
                    Text(
                      'Samyukt',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colours.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusTokens.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colours.accentMuted,
              ),
              child: Icon(icon, size: 18, color: colours.accent),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: kairos.typeScale.body.copyWith(
                      color: colours.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: kairos.typeScale.caption.copyWith(
                      color: colours.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
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
        style: kairos.typeScale.caption.copyWith(
          color: kairos.colours.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colours.accentMuted,
            ),
            child: Icon(icon, size: 18, color: colours.accent),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: kairos.typeScale.body.copyWith(
                    color: colours.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Switch.adaptive(
            value: value,
            activeTrackColor: colours.accent,
            activeThumbColor: colours.onAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
