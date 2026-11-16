import 'package:flutter/material.dart';

import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';

/// Baseline world clock. Offsets are fixed UTC offsets until the bundled IANA
/// timezone service lands (P1-02); DST is therefore not applied yet.
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
  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final now = widget.clock.nowUtc();

    return Scaffold(
      appBar: AppBar(title: const Text('World clock')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          itemCount: _cities.length,
          separatorBuilder: (_, __) => const SizedBox(height: Space.md),
          itemBuilder: (context, index) {
            final city = _cities[index];
            final local = now.add(Duration(minutes: city.utcOffsetMinutes));
            return _CityRow(
              city: city.name,
              time: formatDuration(
                Duration(hours: local.hour, minutes: local.minute),
              ).substring(0, 5),
              offsetMinutes: city.utcOffsetMinutes,
              kairos: kairos,
            );
          },
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.time,
    required this.offsetMinutes,
    required this.kairos,
  });

  final String city;
  final String time;
  final int offsetMinutes;
  final KairosTheme kairos;

  String get _offsetLabel {
    final sign = offsetMinutes < 0 ? '-' : '+';
    final abs = offsetMinutes.abs();
    final hours = (abs ~/ 60).toString().padLeft(2, '0');
    final minutes = (abs % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final colours = kairos.colours;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colours.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: kairos.typeScale.section),
                const SizedBox(height: Space.xxs),
                Text(
                  'UTC$_offsetLabel',
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: kairos.typeScale.title.copyWith(
              color: colours.textPrimary,
              fontFeatures: kairos.typeScale.display.fontFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
