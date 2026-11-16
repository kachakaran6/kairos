import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/glass/glass.dart';
import '../domain/alarm.dart';
import 'alarm_controller.dart';
import 'alarm_ring_page.dart';

class AlarmEditorPage extends ConsumerStatefulWidget {
  const AlarmEditorPage({super.key, this.alarm});

  final Alarm? alarm;

  @override
  ConsumerState<AlarmEditorPage> createState() => _AlarmEditorPageState();
}

class _AlarmEditorPageState extends ConsumerState<AlarmEditorPage> {
  late int _hour;
  late int _minute;
  late final TextEditingController _label;
  late Set<int> _repeatDays;
  late int _wakeWindow;
  late int _volumeRamp;
  late AlarmDismissal _dismissal;
  late bool _skipNext;

  bool get _editing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    final now = TimeOfDay.now();
    _hour = alarm?.hour ?? now.hour;
    _minute = alarm?.minute ?? now.minute;
    _label = TextEditingController(text: alarm?.label ?? '');
    _repeatDays = Set<int>.of(alarm?.repeatDays ?? const <int>{});
    _wakeWindow = alarm?.wakeWindowMinutes ?? 0;
    _volumeRamp = alarm?.volumeRampMinutes ?? 0;
    _dismissal = alarm?.dismissal ?? AlarmDismissal.tap;
    _skipNext = alarm?.skipNext ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  Future<void> _save() async {
    final notifier = ref.read(alarmListProvider.notifier);
    if (_editing) {
      await notifier.replace(
        widget.alarm!.copyWith(
          label: _label.text,
          hour: _hour,
          minute: _minute,
          repeatDays: _repeatDays,
          wakeWindowMinutes: _wakeWindow,
          volumeRampMinutes: _volumeRamp,
          dismissal: _dismissal,
          skipNext: _skipNext,
        ),
      );
    } else {
      await notifier.add(
        label: _label.text,
        hour: _hour,
        minute: _minute,
        repeatDays: _repeatDays,
        wakeWindowMinutes: _wakeWindow,
        volumeRampMinutes: _volumeRamp,
        dismissal: _dismissal,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this alarm?'),
        content: const Text('This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(alarmListProvider.notifier).remove(widget.alarm!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final timeLabel =
        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            _editing ? 'Edit alarm' : 'New alarm',
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GlassButton(
                onPressed: _save,
                intensity: GlassIntensity.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colours.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.phoneMargin,
              vertical: Space.lg,
            ),
            children: <Widget>[
              Center(
                child: GlassCard(
                  intensity: GlassIntensity.primary,
                  borderRadius: BorderRadius.circular(RadiusTokens.xxl),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _pickTime();
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xxl,
                    vertical: Space.lg,
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        timeLabel,
                        style: kairos.typeScale.display.copyWith(
                          color: colours.textPrimary,
                          fontSize: 54,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        'Tap to change time',
                        style: kairos.typeScale.caption.copyWith(
                          color: colours.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              GlassContainer(
                intensity: GlassIntensity.secondary,
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _label,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 16, color: colours.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Label',
                    labelStyle: TextStyle(color: colours.textSecondary),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              const GlassSectionHeader(title: 'REPEAT'),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: <Widget>[
                  for (final day in const <int>[
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ])
                    FilterChip(
                      label: Text(_dayLabel(day)),
                      selected: _repeatDays.contains(day),
                      selectedColor: colours.accent.withValues(alpha: 0.22),
                      backgroundColor: colours.surface.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: _repeatDays.contains(day)
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _repeatDays.contains(day)
                            ? colours.accent
                            : colours.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                        side: BorderSide(
                          color: _repeatDays.contains(day)
                              ? colours.accent
                              : colours.border.withValues(alpha: 0.4),
                        ),
                      ),
                      onSelected: (selected) => setState(() {
                        HapticFeedback.selectionClick();
                        if (selected) {
                          _repeatDays.add(day);
                        } else {
                          _repeatDays.remove(day);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: Space.xxs),
              Text(
                _repeatDays.isEmpty
                    ? 'Once — rings at the next occurrence.'
                    : 'Rings on the selected days.',
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textSecondary,
                ),
              ),
              const SizedBox(height: Space.lg),
              const GlassSectionHeader(title: 'Wake window'),
              GlassSegmentedControl<int>(
                selectedValue: _wakeWindow,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _wakeWindow = val);
                },
                segments: const [
                  GlassSegment(value: 0, label: 'Off'),
                  GlassSegment(value: 15, label: '15 min'),
                  GlassSegment(value: 30, label: '30 min'),
                ],
              ),
              const SizedBox(height: Space.xxs),
              Text(
                'The alarm may ring anywhere inside the window, at the lightest '
                'point available to it.',
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textSecondary,
                ),
              ),
              const SizedBox(height: Space.lg),
              const GlassSectionHeader(title: 'GRADUAL VOLUME RAMP'),
              GlassSegmentedControl<int>(
                selectedValue: _volumeRamp,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _volumeRamp = val);
                },
                segments: const [
                  GlassSegment(value: 0, label: 'Instant'),
                  GlassSegment(value: 1, label: '1 min'),
                  GlassSegment(value: 5, label: '5 min'),
                  GlassSegment(value: 10, label: '10 min'),
                ],
              ),
              const SizedBox(height: Space.xxs),
              Text(
                'Gently ascends from silence to full ringtone volume over the duration.',
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textSecondary,
                ),
              ),
              const SizedBox(height: Space.lg),
              GlassContainer(
                intensity: GlassIntensity.secondary,
                borderRadius: RadiusTokens.mdRadius,
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.bedtime_outlined,
                          size: 16,
                          color: colours.accent,
                        ),
                        const SizedBox(width: Space.xs),
                        Text(
                          '90-Minute Sleep Cycles',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      'Waking at the end of a cycle avoids sleep inertia. Suggested wake times from now:',
                      style: kairos.typeScale.caption.copyWith(
                        color: colours.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: <Widget>[
                        for (final cycle in const <int>[3, 4, 5, 6])
                          _buildCycleChip(context, cycle),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
              GlassContainer(
                intensity: GlassIntensity.secondary,
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: DropdownButtonFormField<AlarmDismissal>(
                  initialValue: _dismissal,
                  dropdownColor: colours.surface,
                  decoration: const InputDecoration(
                    labelText: 'Dismissal',
                    border: InputBorder.none,
                  ),
                  items: const <DropdownMenuItem<AlarmDismissal>>[
                    DropdownMenuItem(
                      value: AlarmDismissal.tap,
                      child: Text('Tap to dismiss'),
                    ),
                    DropdownMenuItem(
                      value: AlarmDismissal.math,
                      child: Text('Solve a sum'),
                    ),
                    DropdownMenuItem(
                      value: AlarmDismissal.phrase,
                      child: Text('Type a phrase'),
                    ),
                    DropdownMenuItem(
                      value: AlarmDismissal.shake,
                      child: Text('Shake the phone'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _dismissal = value);
                  },
                ),
              ),
              if (_editing && _repeatDays.isNotEmpty) ...<Widget>[
                const SizedBox(height: Space.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Skip the next occurrence'),
                  subtitle: const Text('The alarm stays on afterwards.'),
                  value: _skipNext,
                  onChanged: (value) => setState(() => _skipNext = value),
                ),
              ],
              const SizedBox(height: Space.lg),
              GlassButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AlarmRingPage(
                      label: _label.text.trim().isEmpty
                          ? 'Alarm'
                          : _label.text.trim(),
                      timeLabel: timeLabel,
                      volumeRampMinutes: _volumeRamp,
                      dismissal: _dismissal,
                    ),
                  ),
                ),
                intensity: GlassIntensity.subtle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: colours.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Preview the ring',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colours.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_editing) ...<Widget>[
                const SizedBox(height: Space.sm),
                GlassButton(
                  onPressed: _delete,
                  intensity: GlassIntensity.subtle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: colours.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete alarm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colours.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Space.huge),
            ],
          ),
        ),
      ),
    );
  }

  static String _dayLabel(int day) {
    const labels = <int, String>{
      DateTime.monday: 'M',
      DateTime.tuesday: 'T',
      DateTime.wednesday: 'W',
      DateTime.thursday: 'T',
      DateTime.friday: 'F',
      DateTime.saturday: 'S',
      DateTime.sunday: 'S',
    };
    return labels[day] ?? '?';
  }

  Widget _buildCycleChip(BuildContext context, int cycles) {
    final kairos = KairosTheme.of(context);
    final now = DateTime.now();
    final wakeTime = now.add(Duration(minutes: cycles * 90));
    final wakeHour = wakeTime.hour.toString().padLeft(2, '0');
    final wakeMin = wakeTime.minute.toString().padLeft(2, '0');
    final durationHours = (cycles * 1.5)
        .toStringAsFixed(1)
        .replaceAll('.0', '');

    return ActionChip(
      backgroundColor: kairos.colours.surface.withValues(alpha: 0.35),
      side: BorderSide(color: kairos.colours.border.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      label: Text(
        '$cycles cycles ($durationHours h) → $wakeHour:$wakeMin',
        style: kairos.typeScale.caption.copyWith(
          color: kairos.colours.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          _hour = wakeTime.hour;
          _minute = wakeTime.minute;
        });
      },
    );
  }
}
