import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';

/// Pomodoro-style focus timer. 25 minutes of work, 5 minutes of rest.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  static const int _workSeconds = 25 * 60;
  static const int _restSeconds = 5 * 60;

  int _remainingSeconds = _workSeconds;
  int _completedSessions = 0;
  bool _resting = false;
  Timer? _ticker;

  bool get _running => _ticker?.isActive ?? false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() {});
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          if (_resting) {
            _resting = false;
            _remainingSeconds = _workSeconds;
          } else {
            _completedSessions += 1;
            _resting = true;
            _remainingSeconds = _restSeconds;
          }
        });
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _resting = false;
      _remainingSeconds = _workSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Text(
                _resting ? 'Rest' : 'Focus',
                style: kairos.typeScale.section.copyWith(
                  color: kairos.colours.textSecondary,
                ),
              ),
              const SizedBox(height: Space.xs),
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
                '$_completedSessions sessions today',
                style: kairos.typeScale.caption.copyWith(
                  color: kairos.colours.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          Space.touchTargetAndroid,
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
            ],
          ),
        ),
      ),
    );
  }
}
