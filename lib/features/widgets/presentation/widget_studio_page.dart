import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/widget_suite/widget_artwork_renderer.dart';
import '../../../core/widgets/widget_suite/widget_sync_service.dart';
import '../domain/widget_look.dart';

/// Spec: Interactive Widget Studio for tailoring home screen widgets.
class WidgetStudioPage extends ConsumerStatefulWidget {
  const WidgetStudioPage({super.key});

  @override
  ConsumerState<WidgetStudioPage> createState() => _WidgetStudioPageState();
}

enum _WidgetFamily {
  clock,
  nextMoment,
  worldClock,
  thenMoment,
  interactive,
  combo,
}

class _WidgetStudioPageState extends ConsumerState<WidgetStudioPage> {
  _WidgetFamily _selectedFamily = _WidgetFamily.clock;
  int _selectedStyleIndex = 0;
  WidgetLook _activeLook = WidgetLook.all[0];
  double _backgroundOpacity = 1.0;
  double _cornerRoundness = 28.0;
  bool _isSaving = false;

  final List<String> _clockStyles = const [
    'Monolith',
    'Stacked',
    'Editorial',
    'Orbit',
    'Words',
    'Glass',
    'Dayline',
    'Pixel',
  ];

  final List<String> _nextStyles = const [
    'Hero Ring',
    'Compact Chip',
    'List View',
    'Calendar Strip',
    'Poster',
  ];

  final List<String> _worldStyles = const [
    '4 Cities',
    'Globe View',
    'Timeline Planner',
    '2 Cities Compact',
  ];

  final List<String> _thenStyles = const [
    'Days Since',
    'Vertical Timeline',
    'Y/M/D Breakdown',
  ];

  final List<String> _interactiveStyles = const [
    'Alarm & Focus',
    'Timer Presets',
    'Stopwatch',
  ];

  final List<String> _comboStyles = const [
    'Today 4x2',
    'Dashboard 4x4',
    'Life Progress',
    'Zero Day',
  ];

  List<String> get _currentStyles {
    switch (_selectedFamily) {
      case _WidgetFamily.clock:
        return _clockStyles;
      case _WidgetFamily.nextMoment:
        return _nextStyles;
      case _WidgetFamily.worldClock:
        return _worldStyles;
      case _WidgetFamily.thenMoment:
        return _thenStyles;
      case _WidgetFamily.interactive:
        return _interactiveStyles;
      case _WidgetFamily.combo:
        return _comboStyles;
    }
  }

  Future<void> _applyAndSync() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(widgetSyncServiceProvider).syncAllWidgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _activeLook.surfaceColor,
            content: Text(
              'Widgets synchronized with ${_activeLook.name} look!',
              style: TextStyle(color: _activeLook.primaryTextColor),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return KairosScaffold(
      title: 'Widget Studio',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.phoneMargin,
          vertical: Space.md,
        ),
        children: <Widget>[
          // 1. Live Interactive Widget Preview Canvas
          Center(
            child: Container(
              width: 320,
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _activeLook.backgroundColor.withValues(
                  alpha: _backgroundOpacity,
                ),
                borderRadius: BorderRadius.circular(_cornerRoundness),
                border: Border.all(color: _activeLook.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _activeLook.isDark ? 0.4 : 0.08,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildLiveWidgetPreview(),
            ),
          ),

          const SizedBox(height: Space.lg),

          // 2. Widget Family Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _WidgetFamily.values.map((family) {
                final isSelected = family == _selectedFamily;
                final label = switch (family) {
                  _WidgetFamily.clock => 'Clock',
                  _WidgetFamily.nextMoment => 'Next Moment',
                  _WidgetFamily.worldClock => 'World Clock',
                  _WidgetFamily.thenMoment => 'Memories',
                  _WidgetFamily.interactive => 'Instruments',
                  _WidgetFamily.combo => 'Combo',
                };

                return Padding(
                  padding: const EdgeInsets.only(right: Space.xs),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFamily = family;
                          _selectedStyleIndex = 0;
                        });
                      }
                    },
                    selectedColor: colours.accent.withValues(alpha: 0.2),
                    backgroundColor: colours.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colours.accent
                          : colours.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      side: BorderSide(
                        color: isSelected ? colours.accent : colours.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: Space.md),

          // 3. Style Carousel
          Text(
            'STYLE VARIANT',
            style: kairos.typeScale.label.copyWith(color: colours.textTertiary),
          ),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _currentStyles.length,
              separatorBuilder: (_, __) => const SizedBox(width: Space.xs),
              itemBuilder: (context, index) {
                final styleName = _currentStyles[index];
                final isSelected = index == _selectedStyleIndex;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedStyleIndex = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colours.accent
                          : colours.surfaceElevated,
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      border: Border.all(
                        color: isSelected ? colours.accent : colours.border,
                      ),
                    ),
                    child: Text(
                      styleName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colours.onAccent
                            : colours.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: Space.lg),

          // 4. Curated "Looks" Carousel
          Text(
            'CURATED LOOKS',
            style: kairos.typeScale.label.copyWith(color: colours.textTertiary),
          ),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: WidgetLook.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: Space.sm),
              itemBuilder: (context, index) {
                final look = WidgetLook.all[index];
                final isSelected = look.id == _activeLook.id;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeLook = look);
                  },
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: look.surfaceColor,
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                      border: Border.all(
                        color: isSelected ? colours.accent : look.borderColor,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: look.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                look.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: look.primaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          look.isDark ? 'Obsidian' : 'Paper',
                          style: TextStyle(
                            fontSize: 11,
                            color: look.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: Space.lg),

          // 5. Customization Sliders (Opacity & Corner Radius)
          SurfaceCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Background Opacity',
                      style: TextStyle(color: colours.textPrimary),
                    ),
                    Text(
                      '${(_backgroundOpacity * 100).toInt()}%',
                      style: TextStyle(
                        color: colours.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _backgroundOpacity,
                  min: 0.2,
                  max: 1.0,
                  activeColor: colours.accent,
                  onChanged: (val) => setState(() => _backgroundOpacity = val),
                ),
                const SizedBox(height: Space.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Corner Radius',
                      style: TextStyle(color: colours.textPrimary),
                    ),
                    Text(
                      '${_cornerRoundness.toInt()} dp',
                      style: TextStyle(
                        color: colours.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _cornerRoundness,
                  min: 12.0,
                  max: 36.0,
                  activeColor: colours.accent,
                  onChanged: (val) => setState(() => _cornerRoundness = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),

          // 6. Action Button: Apply & Sync
          PillButton(
            onPressed: _isSaving ? null : _applyAndSync,
            label: _isSaving ? 'Synchronizing...' : 'Apply Look & Sync Widgets',
            icon: const Icon(LucideIcons.check, size: 18),
            variant: PillButtonVariant.primary,
          ),
          const SizedBox(height: Space.huge),
        ],
      ),
    );
  }

  Widget _buildLiveWidgetPreview() {
    switch (_selectedFamily) {
      case _WidgetFamily.clock:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '10:30',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w200,
                color: _activeLook.primaryTextColor,
                letterSpacing: -1.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _activeLook.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TUE, 17 NOV',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: _activeLook.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        );

      case _WidgetFamily.nextMoment:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TRAVEL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _activeLook.accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '42',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    color: _activeLook.primaryTextColor,
                  ),
                ),
                Text(
                  'Trip to Kyoto',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'serif',
                    color: _activeLook.primaryTextColor,
                  ),
                ),
              ],
            ),
            WidgetProgressRing(
              progress: 0.72,
              accentColor: _activeLook.accentColor,
              size: 80,
              strokeWidth: 6,
            ),
          ],
        );

      case _WidgetFamily.worldClock:
        return Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'London',
                    style: TextStyle(
                      fontSize: 11,
                      color: _activeLook.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '05:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _activeLook.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tokyo',
                    style: TextStyle(
                      fontSize: 11,
                      color: _activeLook.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '14:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _activeLook.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New York',
                    style: TextStyle(
                      fontSize: 11,
                      color: _activeLook.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '00:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _activeLook.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mumbai',
                    style: TextStyle(
                      fontSize: 11,
                      color: _activeLook.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '10:30',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _activeLook.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case _WidgetFamily.thenMoment:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEMORIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _activeLook.secondaryTextColor,
                letterSpacing: 1.0,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '520',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w200,
                    color: _activeLook.primaryTextColor,
                  ),
                ),
                Text(
                  ' days ago',
                  style: TextStyle(
                    fontSize: 14,
                    color: _activeLook.secondaryTextColor,
                  ),
                ),
              ],
            ),
            Text(
              'Graduation Day',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'serif',
                color: _activeLook.accentColor,
              ),
            ),
          ],
        );

      case _WidgetFamily.interactive:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT ALARM',
                      style: TextStyle(
                        fontSize: 10,
                        color: _activeLook.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '06:30',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: _activeLook.primaryTextColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _activeLook.accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _activeLook.backgroundColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WidgetStreakBars(
              activeDays: const [true, true, true, true, false, true, true],
              accentColor: _activeLook.accentColor,
            ),
          ],
        );

      case _WidgetFamily.combo:
        return Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '10:30',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w200,
                      color: _activeLook.primaryTextColor,
                    ),
                  ),
                  Text(
                    'TUE, 17 NOV',
                    style: TextStyle(
                      fontSize: 10,
                      color: _activeLook.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Alarm 06:30',
                    style: TextStyle(
                      fontSize: 11,
                      color: _activeLook.accentColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 80, color: _activeLook.borderColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT MOMENT',
                    style: TextStyle(
                      fontSize: 9,
                      color: _activeLook.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '42 days',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _activeLook.primaryTextColor,
                    ),
                  ),
                  Text(
                    'Trip to Kyoto',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'serif',
                      color: _activeLook.secondaryTextColor,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
