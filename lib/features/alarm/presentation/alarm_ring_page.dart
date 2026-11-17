import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/pill_button.dart';
import '../domain/alarm.dart';

enum AlarmRingResult { dismiss, snooze }

/// Full-screen immersive ring with breathing radial glow, serif label,
/// huge numerals, and dismissal challenges.
class AlarmRingPage extends StatefulWidget {
  const AlarmRingPage({
    super.key,
    required this.label,
    required this.timeLabel,
    this.volumeRampMinutes = 0,
    this.dismissal = AlarmDismissal.tap,
  });

  final String label;
  final String timeLabel;
  final int volumeRampMinutes;
  final AlarmDismissal dismissal;

  @override
  State<AlarmRingPage> createState() => _AlarmRingPageState();
}

class _AlarmRingPageState extends State<AlarmRingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    switch (widget.dismissal) {
      case AlarmDismissal.tap:
        _finish(AlarmRingResult.dismiss);
        return;
      case AlarmDismissal.math:
        if (await _solveSum()) _finish(AlarmRingResult.dismiss);
        return;
      case AlarmDismissal.phrase:
        if (await _typePhrase()) _finish(AlarmRingResult.dismiss);
        return;
      case AlarmDismissal.shake:
        if (await _shakeInstructions()) _finish(AlarmRingResult.dismiss);
        return;
    }
  }

  void _finish(AlarmRingResult result) {
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<bool> _solveSum() async {
    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MathDismissDialog(),
    );
    return answer ?? false;
  }

  Future<bool> _typePhrase() async {
    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PhraseDismissDialog(),
    );
    return answer ?? false;
  }

  Future<bool> _shakeInstructions() async {
    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ShakeDismissDialog(),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Scaffold(
      backgroundColor: colours.background,
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Breathing Radial Glow behind the time
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1.0 + (_pulseController.value * 0.2);
              final opacity = 0.12 + (_pulseController.value * 0.12);

              return Container(
                width: 320 * scale,
                height: 320 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colours.accent.withValues(alpha: opacity),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colours.accent.withValues(alpha: opacity * 0.7),
                      blurRadius: 72 * scale,
                      spreadRadius: 24 * scale,
                    ),
                  ],
                ),
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.xl,
                vertical: Space.xl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Top Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.alarmClock,
                        size: 20,
                        color: colours.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ALARM RINGING',
                        style: kairos.typeScale.label.copyWith(
                          color: colours.accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  // Center Numerals & Serif Label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.timeLabel,
                          style: kairos.typeScale.display.copyWith(
                            fontSize: 76,
                            fontWeight: FontWeight.w200,
                            color: colours.textPrimary,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: kairos.typeScale.serifTitle.copyWith(
                          color: colours.textPrimary,
                          fontSize: 26,
                        ),
                      ),
                      if (widget.volumeRampMinutes > 0) ...<Widget>[
                        const SizedBox(height: Space.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colours.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              RadiusTokens.pill,
                            ),
                          ),
                          child: Text(
                            'Volume ramping up over ${widget.volumeRampMinutes}m',
                            style: kairos.typeScale.caption.copyWith(
                              color: colours.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bottom Action Buttons: Snooze & Dismiss
                  Column(
                    children: [
                      PillButton(
                        onPressed: _dismiss,
                        label: 'Dismiss Alarm',
                        icon: const Icon(LucideIcons.check, size: 20),
                        variant: PillButtonVariant.primary,
                      ),
                      const SizedBox(height: Space.sm),
                      PillButton(
                        onPressed: () => _finish(AlarmRingResult.snooze),
                        label: 'Snooze 5 minutes',
                        icon: const Icon(LucideIcons.bellOff, size: 18),
                        variant: PillButtonVariant.secondary,
                      ),
                      const SizedBox(height: Space.md),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MathDismissDialog extends StatefulWidget {
  const _MathDismissDialog();

  @override
  State<_MathDismissDialog> createState() => _MathDismissDialogState();
}

class _MathDismissDialogState extends State<_MathDismissDialog> {
  static const int _left = 17;
  static const int _right = 9;
  final TextEditingController _answer = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _check() {
    if (_answer.text.trim() == '${_left + _right}') {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Not yet. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solve to dismiss'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$_left + $_right = ?'),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Answer', errorText: _error),
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: _check, child: const Text('Submit')),
      ],
    );
  }
}

class _PhraseDismissDialog extends StatefulWidget {
  const _PhraseDismissDialog();

  @override
  State<_PhraseDismissDialog> createState() => _PhraseDismissDialogState();
}

class _PhraseDismissDialogState extends State<_PhraseDismissDialog> {
  static const String _phrase = 'I am awake';
  final TextEditingController _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _check() {
    if (_input.text.trim().toLowerCase() == _phrase.toLowerCase()) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Does not match yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Type to dismiss'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Type: "$_phrase"'),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _input,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Phrase', errorText: _error),
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: _check, child: const Text('Submit')),
      ],
    );
  }
}

class _ShakeDismissDialog extends StatefulWidget {
  const _ShakeDismissDialog();

  @override
  State<_ShakeDismissDialog> createState() => _ShakeDismissDialogState();
}

class _ShakeDismissDialogState extends State<_ShakeDismissDialog> {
  int _shakes = 0;

  void _increment() {
    HapticFeedback.mediumImpact();
    setState(() => _shakes += 1);
    if (_shakes >= 5) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shake the phone'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Tap the button or shake 5 times: $_shakes / 5'),
          const SizedBox(height: Space.md),
          ElevatedButton(
            onPressed: _increment,
            child: const Text('Shake count +1'),
          ),
        ],
      ),
    );
  }
}
