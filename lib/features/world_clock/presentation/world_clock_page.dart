import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/surface_card.dart';
import 'world_clock_globe_3d_widget.dart';

class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key, this.clock = const SystemClock()});

  final Clock clock;

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

const List<GlobeCity> _defaultCities = <GlobeCity>[
  GlobeCity(
    name: 'Mumbai',
    utcOffsetMinutes: 330,
    latitude: 19.0760,
    longitude: 72.8777,
  ),
  GlobeCity(
    name: 'London',
    utcOffsetMinutes: 0,
    latitude: 51.5074,
    longitude: -0.1278,
  ),
  GlobeCity(
    name: 'New York',
    utcOffsetMinutes: -300,
    latitude: 40.7128,
    longitude: -74.0060,
  ),
  GlobeCity(
    name: 'Tokyo',
    utcOffsetMinutes: 540,
    latitude: 35.6762,
    longitude: 139.6503,
  ),
  GlobeCity(
    name: 'Sydney',
    utcOffsetMinutes: 600,
    latitude: -33.8688,
    longitude: 151.2093,
  ),
  GlobeCity(
    name: 'Dubai',
    utcOffsetMinutes: 240,
    latitude: 25.2048,
    longitude: 55.2708,
  ),
  GlobeCity(
    name: 'Paris',
    utcOffsetMinutes: 60,
    latitude: 48.8566,
    longitude: 2.3522,
  ),
  GlobeCity(
    name: 'Singapore',
    utcOffsetMinutes: 480,
    latitude: 1.3521,
    longitude: 103.8198,
  ),
  GlobeCity(
    name: 'San Francisco',
    utcOffsetMinutes: -420,
    latitude: 37.7749,
    longitude: -122.4194,
  ),
  GlobeCity(
    name: 'Berlin',
    utcOffsetMinutes: 60,
    latitude: 52.5200,
    longitude: 13.4050,
  ),
  GlobeCity(
    name: 'Toronto',
    utcOffsetMinutes: -300,
    latitude: 43.6532,
    longitude: -79.3832,
  ),
  GlobeCity(
    name: 'Auckland',
    utcOffsetMinutes: 720,
    latitude: -36.8485,
    longitude: 174.7633,
  ),
];

class _WorldClockPageState extends State<WorldClockPage> {
  final TextEditingController _search = TextEditingController();
  List<GlobeCity> _displayedCities = List.of(_defaultCities);
  double _timeTravelHours = 0;
  GlobeCity? _selectedCity;
  GlobeStyle _globeStyle = GlobeStyle.atlas;

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

          // Day/Night Terminator Real 3D Globe
          WorldClockGlobe3DWidget(
            nowUtc: baseNow,
            selectedOffsetMinutes: (_timeTravelHours * 60).round(),
            selectedCity: _selectedCity,
            globeStyle: _globeStyle,
            onGlobeStyleChanged: (style) => setState(() => _globeStyle = style),
            onCitySelected: (city) => setState(() => _selectedCity = city),
            onResetOffset: () {
              HapticFeedback.lightImpact();
              setState(() => _timeTravelHours = 0);
            },
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
                isSelected: _selectedCity?.name == city.name,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCity = city);
                },
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
    this.isSelected = false,
    this.onTap,
  });

  final GlobeCity city;
  final DateTime time;
  final int homeOffsetMinutes;
  final bool isSelected;
  final VoidCallback? onTap;

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          border: Border.all(
            color: isSelected ? colours.accent : Colors.transparent,
            width: isSelected ? 1.5 : 0.0,
          ),
        ),
        child: SurfaceCard(
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  city.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: kairos.typeScale.section.copyWith(
                                    color: colours.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colours.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
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
                        : '$diffSign${diffHours.toStringAsFixed(1)}h',
                    style: kairos.typeScale.caption.copyWith(
                      color: colours.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
