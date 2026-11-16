import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/glass/glass.dart';

/// Monotonic stopwatch with laps. Uses [Stopwatch] so it does not drift when
/// frames are dropped or the screen locks.
class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _laps = <Duration>[];
  Timer? _repaint;

  @override
  void dispose() {
    _repaint?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _repaint?.cancel();
      } else {
        _stopwatch.start();
        _repaint = Timer.periodic(const Duration(milliseconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _lap() {
    if (_stopwatch.elapsed == Duration.zero) return;
    setState(() => _laps.insert(0, _stopwatch.elapsed));
  }

  void _reset() {
    _repaint?.cancel();
    setState(() {
      _stopwatch
        ..stop()
        ..reset();
      _laps.clear();
    });
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centis = (value.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centis';
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Stopwatch',
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
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.phoneMargin,
              vertical: Space.lg,
            ),
            child: Column(
              children: <Widget>[
                const Spacer(),
                GlassContainer(
                  intensity: GlassIntensity.primary,
                  borderRadius: BorderRadius.circular(RadiusTokens.xxl),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xxl,
                    vertical: Space.xxl,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _format(_stopwatch.elapsed),
                      style: kairos.typeScale.display.copyWith(
                        color: colours.textPrimary,
                        fontSize: 54,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GlassButton(
                        onPressed: _stopwatch.isRunning
                            ? () {
                                HapticFeedback.selectionClick();
                                _lap();
                              }
                            : null,
                        intensity: GlassIntensity.subtle,
                        child: Text(
                          'Lap',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _stopwatch.isRunning
                                ? colours.textPrimary
                                : colours.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      flex: 2,
                      child: GlassButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _toggle();
                        },
                        intensity: GlassIntensity.primary,
                        child: Text(
                          _stopwatch.isRunning ? 'Pause' : 'Start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colours.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _reset();
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: colours.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (_laps.isNotEmpty)
                  GlassContainer(
                    intensity: GlassIntensity.secondary,
                    borderRadius: BorderRadius.circular(RadiusTokens.lg),
                    padding: const EdgeInsets.all(Space.md),
                    height: 200,
                    child: ListView.separated(
                      itemCount: _laps.length,
                      separatorBuilder: (_, __) => Divider(
                        height: Space.sm,
                        color: colours.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (context, index) {
                        final lapNumber = _laps.length - index;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Lap $lapNumber',
                              style: kairos.typeScale.caption.copyWith(
                                color: colours.textSecondary,
                              ),
                            ),
                            Text(
                              _format(_laps[index]),
                              style: kairos.typeScale.section.copyWith(
                                color: colours.textPrimary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
