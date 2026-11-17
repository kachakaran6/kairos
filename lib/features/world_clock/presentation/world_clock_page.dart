import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/glass/glass.dart';
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
    const homeOffset = 330; // user's offset (Mumbai)

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'World Clock',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colours.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colours.textPrimary,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            if (_timeTravelHours != 0)
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _timeTravelHours = 0);
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: colours.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.phoneMargin,
              vertical: Space.md,
            ),
            children: <Widget>[
              // Search Input with Glass Look
              GlassContainer(
                height: 48,
                intensity: GlassIntensity.subtle,
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.search_rounded,
                      color: colours.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        style: TextStyle(
                          fontSize: 15,
                          color: colours.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search city or airport code...',
                          hintStyle: TextStyle(
                            color: colours.textTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _search.clear();
                          HapticFeedback.selectionClick();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colours.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),

              // Globe Terminator View
              WorldClockGlobeWidget(
                selectedOffsetMinutes: (_timeTravelHours * 60).round(),
                nowUtc: adjustedNow,
              ),
              const SizedBox(height: Space.sm),

              // Time Travel Meeting Planner Slider
              GlassContainer(
                intensity: GlassIntensity.secondary,
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: colours.accent,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Time-Travel Planner',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colours.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _timeTravelHours == 0
                              ? 'Now'
                              : '${_timeTravelHours > 0 ? "+" : ""}${_timeTravelHours.toStringAsFixed(1)} hours',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _timeTravelHours == 0
                                ? colours.textTertiary
                                : colours.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colours.accent,
                        thumbColor: colours.accent,
                        inactiveTrackColor: colours.border,
                        overlayColor: colours.accent.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _timeTravelHours,
                        min: -12,
                        max: 12,
                        divisions: 48, // 30-min increments
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
                _CityRow(
                  city: city.name,
                  nowUtc: adjustedNow,
                  offsetMinutes: city.utcOffsetMinutes,
                  homeOffsetMinutes: homeOffset,
                  kairos: kairos,
                ),
                const SizedBox(height: Space.sm),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.nowUtc,
    required this.offsetMinutes,
    required this.homeOffsetMinutes,
    required this.kairos,
  });

  final String city;
  final DateTime nowUtc;
  final int offsetMinutes;
  final int homeOffsetMinutes;
  final KairosTheme kairos;

  @override
  Widget build(BuildContext context) {
    final colours = kairos.colours;
    final local = nowUtc.add(Duration(minutes: offsetMinutes));
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final isNight = local.hour < 6 || local.hour >= 19;

    // Difference relative to home
    final diffMinutes = offsetMinutes - homeOffsetMinutes;
    final diffHours = diffMinutes ~/ 60;
    final diffRemMin = (diffMinutes % 60).abs();
    final String offsetLabel;
    if (diffMinutes == 0) {
      offsetLabel = 'Your time';
    } else {
      final sign = diffMinutes > 0 ? '+' : '';
      final minPart = diffRemMin == 0 ? '' : ':$diffRemMin';
      offsetLabel = '$sign$diffHours$minPart hrs';
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final dateLine =
        '${weekdays[local.weekday - 1]}, ${local.day} ${months[local.month - 1]}';

    return GlassCard(
      intensity: GlassIntensity.secondary,
      borderRadius: BorderRadius.circular(RadiusTokens.lg),
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 12),
      child: Row(
        children: <Widget>[
          // day/night indicator bar
          Container(
            width: 3.5,
            height: 42,
            decoration: BoxDecoration(
              color: isNight ? colours.night : colours.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colours.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateLine,
                  style: TextStyle(fontSize: 13, color: colours.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                time,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: isNight ? colours.textSecondary : colours.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                offsetLabel,
                style: TextStyle(fontSize: 12, color: colours.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
