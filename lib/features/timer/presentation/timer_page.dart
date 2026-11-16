import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/glass/glass.dart';

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
    final colours = kairos.colours;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Timer',
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatDuration(Duration(seconds: _remainingSeconds)),
                          style: kairos.typeScale.display.copyWith(
                            color: colours.textPrimary,
                            fontSize: 54,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        _running ? 'Running' : 'Paused',
                        style: kairos.typeScale.caption.copyWith(
                          color: _running
                              ? colours.accent
                              : colours.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    for (final preset in _presets)
                      ChoiceChip(
                        label: Text('$preset min'),
                        selected: _totalSeconds == preset * 60,
                        selectedColor: colours.accent.withValues(alpha: 0.22),
                        backgroundColor: colours.surface.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: _totalSeconds == preset * 60
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _totalSeconds == preset * 60
                              ? colours.accent
                              : colours.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.pill,
                          ),
                          side: BorderSide(
                            color: _totalSeconds == preset * 60
                                ? colours.accent
                                : colours.border.withValues(alpha: 0.4),
                          ),
                        ),
                        onSelected: (_) => _selectPreset(preset),
                      ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GlassButton(
                        onPressed: _reset,
                        intensity: GlassIntensity.subtle,
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colours.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      flex: 2,
                      child: GlassButton(
                        onPressed: _toggle,
                        intensity: GlassIntensity.primary,
                        child: Text(
                          _running ? 'Pause' : 'Start',
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
                const SizedBox(height: Space.sm),
                TextButton(
                  onPressed: _addMinute,
                  child: Text(
                    '+1 minute',
                    style: TextStyle(
                      color: colours.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
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
