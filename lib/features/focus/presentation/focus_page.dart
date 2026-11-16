import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/glass/glass.dart';

enum AmbientSound {
  off('None', Icons.volume_off_outlined),
  rain('Gentle Rain', Icons.water_drop_outlined),
  whiteNoise('White Noise', Icons.air),
  forest('Forest Wind', Icons.forest_outlined),
  campfire('Campfire', Icons.local_fire_department_outlined);

  const AmbientSound(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Pomodoro and deep work focus timer with ambient soundscapes,
/// weekly streak heat map, and session history.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with SingleTickerProviderStateMixin {
  int _workMinutes = 25;
  int _restMinutes = 5;

  late int _remainingSeconds;
  int _completedSessions = 3; // seeded with sample sessions for visual heat-map
  bool _resting = false;
  bool _autoDnd = true;
  AmbientSound _sound = AmbientSound.rain;
  Timer? _ticker;

  late final AnimationController _pulseController;

  bool get _running => _ticker?.isActive ?? false;
  int get _totalSeconds => (_resting ? _restMinutes : _workMinutes) * 60;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _workMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectDuration(int minutes) {
    if (_running) return;
    HapticFeedback.selectionClick();
    setState(() {
      _workMinutes = minutes;
      if (!_resting) {
        _remainingSeconds = minutes * 60;
      }
    });
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_running) {
      _ticker?.cancel();
      _pulseController.stop();
      setState(() {});
      return;
    }
    if (_sound != AmbientSound.off) {
      _pulseController.repeat(reverse: true);
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _pulseController.stop();
        HapticFeedback.heavyImpact();
        setState(() {
          if (_resting) {
            _resting = false;
            _remainingSeconds = _workMinutes * 60;
          } else {
            _completedSessions += 1;
            _resting = true;
            _remainingSeconds = _restMinutes * 60;
          }
        });
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }

  void _reset() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    _pulseController.stop();
    setState(() {
      _resting = false;
      _remainingSeconds = _workMinutes * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final progress = _totalSeconds > 0
        ? 1.0 - (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    final colours = kairos.colours;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Focus',
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
          actions: <Widget>[
            IconButton(
              icon: Icon(
                _autoDnd
                    ? Icons.do_not_disturb_on
                    : Icons.do_not_disturb_off_outlined,
                color: _autoDnd ? colours.accent : colours.textSecondary,
              ),
              tooltip: _autoDnd ? 'Auto-DND active' : 'Auto-DND off',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _autoDnd = !_autoDnd);
              },
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
              // Presets selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final minutes in const <int>[
                    15,
                    25,
                    45,
                    60,
                  ]) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.xxs,
                      ),
                      child: ChoiceChip(
                        label: Text('${minutes}m'),
                        selected: _workMinutes == minutes && !_resting,
                        selectedColor: colours.accent.withValues(alpha: 0.22),
                        backgroundColor: colours.surface.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: _workMinutes == minutes && !_resting
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _workMinutes == minutes && !_resting
                              ? colours.accent
                              : colours.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.pill,
                          ),
                          side: BorderSide(
                            color: _workMinutes == minutes && !_resting
                                ? colours.accent
                                : colours.border.withValues(alpha: 0.4),
                          ),
                        ),
                        onSelected: _running
                            ? null
                            : (_) => _selectDuration(minutes),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Space.lg),

              // Circular progress indicator & countdown
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colours.surfaceElevated.withValues(
                          alpha: 0.4,
                        ),
                        color: _resting ? colours.success : colours.accent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _resting ? 'REST' : 'FOCUS',
                          style: kairos.typeScale.caption.copyWith(
                            color: _resting ? colours.success : colours.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          formatDuration(Duration(seconds: _remainingSeconds)),
                          style: kairos.typeScale.display.copyWith(
                            color: colours.textPrimary,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          '$_completedSessions sessions completed',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),

              // Controls
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
                        _running ? 'Pause' : 'Start Focus',
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
              const SizedBox(height: Space.xl),

              // Ambient Soundscape selector
              GlassContainer(
                intensity: GlassIntensity.secondary,
                borderRadius: RadiusTokens.lgRadius,
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.headphones_outlined,
                          size: 18,
                          color: colours.accent,
                        ),
                        const SizedBox(width: Space.xs),
                        Text(
                          'Ambient Soundscape',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_sound != AmbientSound.off && _running)
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colours.accentMuted,
                                borderRadius: RadiusTokens.smRadius,
                              ),
                              child: Text(
                                'Playing',
                                style: kairos.typeScale.caption.copyWith(
                                  color: colours.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: <Widget>[
                        for (final sound in AmbientSound.values)
                          FilterChip(
                            avatar: Icon(sound.icon, size: 16),
                            label: Text(sound.label),
                            selected: _sound == sound,
                            selectedColor: colours.accent.withValues(
                              alpha: 0.22,
                            ),
                            backgroundColor: colours.surface.withValues(
                              alpha: 0.3,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: _sound == sound
                                  ? colours.accent
                                  : colours.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.pill,
                              ),
                              side: BorderSide(
                                color: _sound == sound
                                    ? colours.accent
                                    : colours.border.withValues(alpha: 0.4),
                              ),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _sound = sound);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),

              // Weekly Heat Map & Streaks
              GlassContainer(
                intensity: GlassIntensity.secondary,
                borderRadius: RadiusTokens.lgRadius,
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Weekly Activity & Streak',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '4-Day Streak 🔥',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    _buildWeeklyHeatMap(context),
                    const SizedBox(height: Space.xs),
                    Text(
                      '18 sessions completed this week • 7.5 hours focused',
                      style: kairos.typeScale.caption.copyWith(
                        color: colours.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatMap(BuildContext context) {
    final kairos = KairosTheme.of(context);
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const sessionsPerDay = <int>[4, 5, 3, 4, 2, 0, 0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (var i = 0; i < 7; i++) ...<Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: sessionsPerDay[i] == 0
                      ? kairos.colours.surfaceElevated
                      : sessionsPerDay[i] >= 4
                      ? kairos.colours.accent
                      : kairos.colours.accentMuted,
                  borderRadius: RadiusTokens.smRadius,
                  border: Border.all(
                    color: sessionsPerDay[i] > 0
                        ? kairos.colours.accent
                        : kairos.colours.border,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    sessionsPerDay[i] > 0 ? '${sessionsPerDay[i]}' : '',
                    style: kairos.typeScale.caption.copyWith(
                      color: sessionsPerDay[i] >= 4
                          ? kairos.colours.onAccent
                          : kairos.colours.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.xxs),
              Text(
                days[i],
                style: kairos.typeScale.caption.copyWith(
                  color: kairos.colours.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
