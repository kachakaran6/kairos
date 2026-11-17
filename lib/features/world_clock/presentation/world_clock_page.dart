import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/surface_card.dart';
import 'world_clock_globe_widget.dart';

class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key, this.clock = const SystemClock()});

  final Clock clock;

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _City {
  const _City(this.name, this.utcOffsetMinutes);

  final String name;
  final int utcOffsetMinutes;
}

const List<_City> _defaultCities = <_City>[
  _City('Mumbai', 330),
  _City('London', 0),
  _City('New York', -300),
  _City('Tokyo', 540),
  _City('Sydney', 600),
  _City('Dubai', 240),
  _City('Paris', 60),
  _City('Singapore', 480),
  _City('San Francisco', -420),
  _City('Berlin', 60),
  _City('Toronto', -300),
  _City('Auckland', 720),
];

class _WorldClockPageState extends State<WorldClockPage> {
  final TextEditingController _search = TextEditingController();
  List<_City> _displayedCities = List.of(_defaultCities);
  double _timeTravelHours = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(_filterCities);
  }

  void _filterCities() {
    final query = _search.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _displayedCities = List.of(_defaultCities);
      } else {
        _displayedCities = _defaultCities
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final baseNow = widget.clock.nowUtc();
    final adjustedNow = baseNow.add(
      Duration(minutes: (_timeTravelHours * 60).round()),
    );
    const homeOffset = 330; // user's home offset (Mumbai)

    return KairosScaffold(
      title: 'World Clock',
      showBackButton: true,
      actions: [
        if (_timeTravelHours != 0)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _timeTravelHours = 0);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Reset',
                style: TextStyle(
                  color: colours.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        children: <Widget>[
          // Search Input
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: colours.surface,
              borderRadius: BorderRadius.circular(RadiusTokens.input),
              border: Border.all(color: colours.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: <Widget>[
                Icon(LucideIcons.search, color: colours.textTertiary, size: 18),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: TextStyle(color: colours.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search city or airport code...',
                      hintStyle: TextStyle(
                        color: colours.textTertiary,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_search.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _search.clear();
                      _filterCities();
                    },
                    child: Icon(
                      LucideIcons.x,
                      color: colours.textTertiary,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: Space.md),

          // Day/Night Terminator 3D Globe
          WorldClockGlobeWidget(
            nowUtc: baseNow,
            selectedOffsetMinutes: (_timeTravelHours * 60).round(),
          ),

          const SizedBox(height: Space.md),

          // Time Travel Planner Slider
          SurfaceCard(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.sliders,
                          size: 15,
                          color: colours.accent,
                        ),
                        const SizedBox(width: Space.xs),
                        Text(
                          'Time-Travel Planner',
                          style: kairos.typeScale.section.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colours.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _timeTravelHours == 0
                          ? 'Now'
                          : '${_timeTravelHours > 0 ? "+" : ""}${_timeTravelHours.toStringAsFixed(1)}h',
                      style: kairos.typeScale.caption.copyWith(
                        color: _timeTravelHours == 0
                            ? colours.textSecondary
                            : colours.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    activeTrackColor: colours.accent,
                    inactiveTrackColor: colours.border,
                    thumbColor: colours.accent,
                    overlayColor: colours.accent.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _timeTravelHours,
                    min: -12.0,
                    max: 12.0,
                    divisions: 48,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _timeTravelHours = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.lg),

          // Cities List
          for (final city in _displayedCities) ...<Widget>[
            Dismissible(
              key: ValueKey(city.name),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                setState(() => _displayedCities.remove(city));
                HapticFeedback.mediumImpact();
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: colours.danger,
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
                child: const Icon(LucideIcons.trash2, color: Colors.white),
              ),
              child: _CityRow(
                city: city,
                time: adjustedNow.add(Duration(minutes: city.utcOffsetMinutes)),
                homeOffsetMinutes: homeOffset,
              ),
            ),
            const SizedBox(height: Space.sm),
          ],
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.time,
    required this.homeOffsetMinutes,
  });

  final _City city;
  final DateTime time;
  final int homeOffsetMinutes;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    final hourStr = time.hour.toString().padLeft(2, '0');
    final minStr = time.minute.toString().padLeft(2, '0');

    final diffMinutes = city.utcOffsetMinutes - homeOffsetMinutes;
    final diffHours = diffMinutes / 60.0;
    final diffSign = diffHours >= 0 ? '+' : '';
    final isHome = diffMinutes == 0;

    final isDay = time.hour >= 6 && time.hour < 18;

    final weekdays = const <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final months = const <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${weekdays[time.weekday - 1]}, ${time.day} ${months[time.month - 1]}';

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Row(
              children: [
                Icon(
                  isDay ? LucideIcons.sun : LucideIcons.moon,
                  size: 18,
                  color: isDay ? colours.accent : colours.night,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kairos.typeScale.section.copyWith(
                          color: colours.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: Space.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$hourStr:$minStr',
                style: kairos.typeScale.title.copyWith(
                  color: colours.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                isHome
                    ? 'Your time'
                    : '$diffSign${diffHours.toStringAsFixed(1)} hrs',
                style: kairos.typeScale.caption.copyWith(
                  color: isHome ? colours.accent : colours.textSecondary,
                  fontWeight: isHome ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
