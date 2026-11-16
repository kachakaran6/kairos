import 'package:flutter/material.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';

/// World clock baseline: city list with day/night bar, date line and
/// offset in words. Search and dial strip are open (P1-03).
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

const List<_City> _cities = <_City>[
  _City('Mumbai', 330),
  _City('London', 0),
  _City('New York', -300),
  _City('Tokyo', 540),
  _City('Sydney', 600),
  _City('Dubai', 240),
  _City('Paris', 60),
  _City('Singapore', 480),
];

class _WorldClockPageState extends State<WorldClockPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final now = widget.clock.nowUtc();
    final homeOffset = 330; // user's offset (Mumbai default)

    return Scaffold(
      backgroundColor: colours.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colours.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'World clock',
                    textAlign: TextAlign.center,
                    style: kairos.typeScale.title.copyWith(
                      color: colours.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: Space.touchTargetIos),
              ],
            ),
            const SizedBox(height: Space.lg),
            // Search field
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: colours.surface,
                borderRadius: RadiusTokens.mdRadius,
                border: Border.all(color: colours.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Row(
                children: <Widget>[
                  Icon(Icons.search, color: colours.textTertiary, size: 20),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      style: kairos.typeScale.body.copyWith(
                        color: colours.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search a city or airport code',
                        hintStyle: kairos.typeScale.body.copyWith(
                          color: colours.textTertiary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            for (final city in _cities) ...<Widget>[
              _CityRow(
                city: city.name,
                nowUtc: now,
                offsetMinutes: city.utcOffsetMinutes,
                homeOffsetMinutes: homeOffset,
                kairos: kairos,
              ),
              const SizedBox(height: Space.sm),
            ],
            const SizedBox(height: Space.md),
            TextButton(
              onPressed: () {},
              child: Text(
                '+ Add city',
                style: kairos.typeScale.body.copyWith(color: colours.accent),
              ),
            ),
          ],
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
    final diff = offsetMinutes - homeOffsetMinutes;
    String offsetLabel;
    if (diff == 0) {
      offsetLabel = 'same as you';
    } else {
      final sign = diff > 0 ? 'ahead of you' : 'behind you';
      final abs = diff.abs();
      final h = abs ~/ 60;
      final m = abs % 60;
      final mm = m == 0 ? '' : ':${m.toString().padLeft(2, '0')}';
      offsetLabel = '$h$mm $sign';
    }
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
    final weekdays = const <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final dateLine =
        '${weekdays[local.weekday - 1]}, ${local.day} ${months[local.month - 1]}';

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: RadiusTokens.mdRadius,
        border: Border.all(color: colours.border),
      ),
      child: Row(
        children: <Widget>[
          // day/night bar
          Container(
            width: 3,
            height: 40,
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
                  style: kairos.typeScale.section.copyWith(
                    fontSize: 17,
                    color: colours.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  dateLine,
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textTertiary,
                  ),
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
                style: kairos.typeScale.title.copyWith(
                  fontSize: 28,
                  color: isNight ? colours.textSecondary : colours.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                offsetLabel,
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
