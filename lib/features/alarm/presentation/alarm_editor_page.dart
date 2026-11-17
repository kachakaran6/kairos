import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_chips.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/kairos_segmented_control.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
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

    return KairosScaffold(
      title: _editing ? 'Edit alarm' : 'New alarm',
      showBackButton: true,
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: Space.md),
              children: <Widget>[
                // Hero Tappable Time Display
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _pickTime();
                    },
                    child: SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            timeLabel,
                            style: kairos.typeScale.display.copyWith(
                              color: colours.textPrimary,
                              fontSize: 64,
                              fontWeight: FontWeight.w200,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: colours.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to change time',
                                style: kairos.typeScale.caption.copyWith(
                                  color: colours.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Space.lg),

                // Label Section
                Text(
                  'LABEL',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                SurfaceCard(
                  borderRadius: BorderRadius.circular(RadiusTokens.input),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: 14,
                  ),
                  child: TextField(
                    controller: _label,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colours.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Alarm label (e.g. Morning Run)',
                      hintStyle: TextStyle(color: colours.textTertiary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  ),
                ),

                const SizedBox(height: Space.lg),

                // Repeat Days Section
                Text(
                  'REPEAT',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(7, (i) {
                    final dayNum = i + 1;
                    return KairosDayChip(
                      dayNumber: dayNum,
                      selected: _repeatDays.contains(dayNum),
                      onToggle: () {
                        setState(() {
                          if (_repeatDays.contains(dayNum)) {
                            _repeatDays.remove(dayNum);
                          } else {
                            _repeatDays.add(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),

                const SizedBox(height: Space.lg),

                // Wake Window Segmented Control
                Text(
                  'WAKE WINDOW',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'The alarm may ring anywhere inside the window, at the lightest point available.',
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                KairosSegmentedControl<int>(
                  items: const <int, String>{
                    0: 'Off',
                    15: '15 min',
                    30: '30 min',
                  },
                  selected: _wakeWindow,
                  onChanged: (val) => setState(() => _wakeWindow = val),
                ),

                const SizedBox(height: Space.lg),

                // Gradual Volume Ramp Segmented Control
                Text(
                  'GRADUAL VOLUME RAMP',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Gently ascends from silence to full ringtone volume.',
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                KairosSegmentedControl<int>(
                  items: const <int, String>{
                    0: 'Instant',
                    1: '1 min',
                    5: '5 min',
                    10: '10 min',
                  },
                  selected: _volumeRamp,
                  onChanged: (val) => setState(() => _volumeRamp = val),
                ),

                const SizedBox(height: Space.lg),

                // Dismissal Puzzle Selector
                Text(
                  'DISMISSAL CHALLENGE',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                KairosSegmentedControl<AlarmDismissal>(
                  items: const <AlarmDismissal, String>{
                    AlarmDismissal.tap: 'Simple Tap',
                    AlarmDismissal.math: 'Math Puzzle',
                    AlarmDismissal.shake: 'Shake Phone',
                  },
                  selected: _dismissal,
                  onChanged: (val) => setState(() => _dismissal = val),
                ),

                const SizedBox(height: Space.lg),

                // 90-Minute Sleep Cycles Recommendations
                SurfaceCard(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.moon,
                            size: 16,
                            color: colours.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '90-Minute Sleep Cycles',
                            style: kairos.typeScale.section.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colours.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waking at the end of a cycle avoids sleep inertia. Suggested wake times:',
                        style: kairos.typeScale.caption.copyWith(
                          color: colours.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: <Widget>[
                          _buildCycleChip(context, 4),
                          _buildCycleChip(context, 5),
                          _buildCycleChip(context, 6),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),

                // Preview Ring Button
                PillButton(
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
                  label: 'Preview Alarm Ring',
                  icon: const Icon(LucideIcons.bell, size: 18),
                  variant: PillButtonVariant.secondary,
                ),

                if (_editing) ...<Widget>[
                  const SizedBox(height: Space.sm),
                  PillButton(
                    onPressed: _delete,
                    label: 'Delete Alarm',
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    variant: PillButtonVariant.ghost,
                  ),
                ],

                const SizedBox(height: Space.md),
              ],
            ),
          ),

          // Sticky Save Button in Thumb Zone
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.md),
            child: PillButton(
              onPressed: _save,
              label: 'Save Alarm',
              icon: const Icon(LucideIcons.check, size: 18),
              variant: PillButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _hour = wakeTime.hour;
          _minute = wakeTime.minute;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kairos.colours.surfaceElevated,
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          border: Border.all(color: kairos.colours.border),
        ),
        child: Text(
          '$cycles cycles ($durationHours h) → $wakeHour:$wakeMin',
          style: kairos.typeScale.caption.copyWith(
            color: kairos.colours.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
