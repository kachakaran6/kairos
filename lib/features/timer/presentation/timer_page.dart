import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';

/// Countdown timer with presets. Runs while the screen is open; persistence and
/// background alarms land with the timer data layer (P1-09).
class TimerPage extends StatefulWidget {
  const TimerPage({super.key, this.initialMinutes = 5});

  final int initialMinutes;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const List<int> _presets = <int>[1, 5, 10, 25];

  late int _totalSeconds = widget.initialMinutes * 60;
  late int _remainingSeconds = widget.initialMinutes * 60;
  Timer? _ticker;

  bool get _running => _ticker?.isActive ?? false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    _ticker?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() {});
      return;
    }
    if (_remainingSeconds == 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        HapticFeedback.mediumImpact();
        _showFinished();
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }

  void _reset() {
    _ticker?.cancel();
    setState(() => _remainingSeconds = _totalSeconds);
  }

  void _addMinute() {
    setState(() {
      _totalSeconds += 60;
      _remainingSeconds += 60;
    });
  }

  Future<void> _showFinished() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Time's up"),
        content: const Text('Your timer has finished.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
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
                  formatDuration(Duration(seconds: _remainingSeconds)),
                  style: kairos.typeScale.display.copyWith(
                    color: kairos.colours.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                _running ? 'Running' : 'Paused',
                style: kairos.typeScale.caption.copyWith(
                  color: kairos.colours.textSecondary,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final preset in _presets)
                    ChoiceChip(
                      label: Text('$preset min'),
                      selected: _totalSeconds == preset * 60,
                      onSelected: (_) => _selectPreset(preset),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          Space.touchTargetAndroid,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: RadiusTokens.mdRadius,
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _toggle,
                      child: Text(_running ? 'Pause' : 'Start'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              TextButton(
                onPressed: _addMinute,
                child: const Text('Add one minute'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
