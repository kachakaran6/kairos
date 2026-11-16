import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
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
    final timeLabel =
        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit alarm' : 'New alarm')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          children: <Widget>[
            Center(
              child: InkWell(
                borderRadius: RadiusTokens.lgRadius,
                onTap: _pickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.sm,
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        timeLabel,
                        style: kairos.typeScale.display.copyWith(
                          color: kairos.colours.textPrimary,
                        ),
                      ),
                      Text(
                        'Tap to change',
                        style: kairos.typeScale.caption.copyWith(
                          color: kairos.colours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _label,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: Space.sm),
            Text('Repeat', style: kairos.typeScale.section),
            const SizedBox(height: Space.xs),
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
                    onSelected: (selected) => setState(() {
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
                color: kairos.colours.textSecondary,
              ),
            ),
            const SizedBox(height: Space.lg),
            Text('Wake window', style: kairos.typeScale.section),
            const SizedBox(height: Space.xs),
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment(value: 0, label: Text('Off')),
                ButtonSegment(value: 15, label: Text('15 min')),
                ButtonSegment(value: 30, label: Text('30 min')),
              ],
              selected: <int>{_wakeWindow},
              onSelectionChanged: (value) =>
                  setState(() => _wakeWindow = value.first),
            ),
            const SizedBox(height: Space.xxs),
            Text(
              'The alarm may ring anywhere inside the window, at the lightest '
              'point available to it.',
              style: kairos.typeScale.caption.copyWith(
                color: kairos.colours.textSecondary,
              ),
            ),
            const SizedBox(height: Space.lg),
            Text('Gradual volume ramp', style: kairos.typeScale.section),
            const SizedBox(height: Space.xs),
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment(value: 0, label: Text('Instant')),
                ButtonSegment(value: 1, label: Text('1 min')),
                ButtonSegment(value: 5, label: Text('5 min')),
                ButtonSegment(value: 10, label: Text('10 min')),
              ],
              selected: <int>{_volumeRamp},
              onSelectionChanged: (value) =>
                  setState(() => _volumeRamp = value.first),
            ),
            const SizedBox(height: Space.xxs),
            Text(
              'Gently ascends from silence to full ringtone volume over the duration.',
              style: kairos.typeScale.caption.copyWith(
                color: kairos.colours.textSecondary,
              ),
            ),
            const SizedBox(height: Space.lg),
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: kairos.colours.surface,
                borderRadius: RadiusTokens.mdRadius,
                border: Border.all(color: kairos.colours.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.bedtime_outlined,
                        size: 16,
                        color: kairos.colours.accent,
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        '90-Minute Sleep Cycles',
                        style: kairos.typeScale.caption.copyWith(
                          color: kairos.colours.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    'Waking at the end of a cycle avoids sleep inertia. Suggested wake times from now:',
                    style: kairos.typeScale.caption.copyWith(
                      color: kairos.colours.textSecondary,
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
            DropdownButtonFormField<AlarmDismissal>(
              initialValue: _dismissal,
              decoration: const InputDecoration(labelText: 'Dismissal'),
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
            OutlinedButton.icon(
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
              icon: const Icon(Icons.play_arrow),
              label: const Text('Preview the ring'),
            ),
            const SizedBox(height: Space.sm),
            ElevatedButton(
              onPressed: _save,
              child: Text(_editing ? 'Save alarm' : 'Add alarm'),
            ),
            if (_editing) ...<Widget>[
              const SizedBox(height: Space.xs),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete alarm'),
              ),
            ],
            const SizedBox(height: Space.huge),
          ],
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
      backgroundColor: kairos.colours.surface,
      side: BorderSide(color: kairos.colours.border),
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
