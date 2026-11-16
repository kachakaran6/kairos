import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../domain/alarm.dart';

enum AlarmRingResult { dismiss, snooze }

/// Full-screen ring. One number, two choices, and the dismissal the user chose
/// for this alarm.
class AlarmRingPage extends StatefulWidget {
  const AlarmRingPage({
    super.key,
    required this.label,
    required this.timeLabel,
    this.dismissal = AlarmDismissal.tap,
  });

  final String label;
  final String timeLabel;
  final AlarmDismissal dismissal;

  @override
  State<AlarmRingPage> createState() => _AlarmRingPageState();
}

class _AlarmRingPageState extends State<AlarmRingPage> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
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
      builder: (context) => AlertDialog(
        title: const Text('Shake the phone'),
        content: const Text(
          'Shake the phone to dismiss. If shaking is not possible, tap the '
          'fallback below.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("I'm awake"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep ringing'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.xl,
          ),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Icon(Icons.alarm, size: Space.xxxl, color: kairos.colours.accent),
              const SizedBox(height: Space.lg),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.timeLabel,
                  style: kairos.typeScale.display.copyWith(
                    color: kairos.colours.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: kairos.typeScale.title.copyWith(
                  color: kairos.colours.textPrimary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _finish(AlarmRingResult.snooze),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      Space.touchTargetAndroid,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: RadiusTokens.mdRadius,
                    ),
                  ),
                  child: const Text('Snooze 5 minutes'),
                ),
              ),
              const SizedBox(height: Space.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dismiss,
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep ringing'),
        ),
        TextButton(onPressed: _check, child: const Text('Dismiss')),
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
  final TextEditingController _typed = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _check() {
    if (_typed.text.trim().toLowerCase() == _phrase.toLowerCase()) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Type "$_phrase" exactly.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Type to dismiss'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Type "$_phrase".'),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _typed,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: 'Phrase', errorText: _error),
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep ringing'),
        ),
        TextButton(onPressed: _check, child: const Text('Dismiss')),
      ],
    );
  }
}
