import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Stopwatch')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          child: Column(
            children: <Widget>[
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _format(_stopwatch.elapsed),
                  style: kairos.typeScale.display.copyWith(
                    color: kairos.colours.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _stopwatch.isRunning ? _lap : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          Space.touchTargetAndroid,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: RadiusTokens.mdRadius,
                        ),
                      ),
                      child: const Text('Lap'),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _toggle,
                      child: Text(_stopwatch.isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              TextButton(onPressed: _reset, child: const Text('Reset')),
              const Spacer(),
              if (_laps.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    itemCount: _laps.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Space.xxs),
                    itemBuilder: (context, index) {
                      final lapNumber = _laps.length - index;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Lap $lapNumber',
                            style: kairos.typeScale.caption.copyWith(
                              color: kairos.colours.textSecondary,
                            ),
                          ),
                          Text(
                            _format(_laps[index]),
                            style: kairos.typeScale.section,
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
    );
  }
}
