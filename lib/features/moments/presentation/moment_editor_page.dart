import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/countdown.dart';
import '../../../core/widgets/kairos_chips.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/kairos_segmented_control.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/moment.dart';
import 'moment_controller.dart';

class MomentEditorPage extends ConsumerStatefulWidget {
  const MomentEditorPage({super.key, this.moment});

  final Moment? moment;

  @override
  ConsumerState<MomentEditorPage> createState() => _MomentEditorPageState();
}

class _MomentEditorPageState extends ConsumerState<MomentEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _notes;

  late DateTime _date;
  DateTime? _endDate;
  late bool _allDay;
  late MomentDirection _direction;
  late MomentCategory _category;
  late CountingMode _countingMode;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.moment != null && widget.moment!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final moment = widget.moment;
    final local =
        moment?.targetUtc.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
    _title = TextEditingController(text: moment?.title ?? '');
    _subtitle = TextEditingController(text: moment?.subtitle ?? '');
    _notes = TextEditingController(text: moment?.notes ?? '');
    _date = DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    _endDate = moment?.endUtc?.toLocal();
    _allDay = moment?.isAllDay ?? true;
    _direction = moment?.direction ?? MomentDirection.down;
    _category = moment?.category ?? MomentCategory.custom;
    _countingMode = moment?.countingMode ?? CountingMode.days;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({bool end = false}) async {
    HapticFeedback.selectionClick();
    final initial = end
        ? (_endDate ?? _date.add(const Duration(days: 1)))
        : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null) return;
    setState(() {
      if (end) {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
      } else {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      }
    });
  }

  Future<void> _pickTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(
      () => _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Give this moment a title.');
      return;
    }
    if (_endDate != null && !_endDate!.isAfter(_date)) {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'The end must be after the start.');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _error = null;
    });

    final targetUtc = _allDay
        ? DateTime.utc(_date.year, _date.month, _date.day).toUtc()
        : _date.toUtc();
    final endUtc = _endDate == null
        ? null
        : DateTime.utc(_endDate!.year, _endDate!.month, _endDate!.day).toUtc();

    final notifier = ref.read(momentListProvider.notifier);
    if (_editing) {
      await notifier.replace(
        widget.moment!.copyWith(
          title: title,
          subtitle: _subtitle.text,
          targetUtc: targetUtc,
          endUtc: endUtc,
          isAllDay: _allDay,
          direction: _direction,
          category: _category,
          countingMode: _countingMode,
          notes: _notes.text,
        ),
      );
    } else {
      await notifier.add(
        title: title,
        subtitle: _subtitle.text,
        targetUtc: targetUtc,
        endUtc: endUtc,
        isAllDay: _allDay,
        direction: _direction,
        category: _category,
        countingMode: _countingMode,
        notes: _notes.text,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';
    final timeStr =
        '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}';

    final isPast =
        _direction == MomentDirection.up || _date.isBefore(DateTime.now());

    return KairosScaffold(
      title: _editing
          ? 'Edit Moment'
          : (isPast ? 'New Past Date' : 'New Moment'),
      showBackButton: true,
      body: Column(
        children: <Widget>[
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: Space.sm),
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: colours.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 18,
                    color: colours.danger,
                  ),
                  const SizedBox(width: Space.sm),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: colours.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: Space.md),
              children: <Widget>[
                // Title and Subtitle Card
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _title,
                        maxLength: 60,
                        style: TextStyle(
                          fontSize: 17,
                          color: colours.textPrimary,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'What are you counting to?',
                          hintStyle: TextStyle(color: colours.textTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: colours.border),
                      TextField(
                        controller: _subtitle,
                        maxLength: 80,
                        style: TextStyle(
                          fontSize: 14,
                          color: colours.textSecondary,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Subtitle or description (optional)',
                          hintStyle: TextStyle(color: colours.textTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),

                // Category Chips
                Text(
                  'CATEGORY',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: MomentCategory.values.map((cat) {
                    final isSelected = _category == cat;
                    return KairosChoiceChip(
                      label: cat.name.toUpperCase(),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),

                const SizedBox(height: Space.lg),

                // Target Date & Time
                Text(
                  'DATE & TIME',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      // All Day Toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All-day',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colours.textPrimary,
                              ),
                            ),
                            Switch.adaptive(
                              value: _allDay,
                              activeTrackColor: colours.accent,
                              activeThumbColor: colours.onAccent,
                              onChanged: (val) => setState(() => _allDay = val),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: colours.border),
                      // Target Date Row
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          onTap: () => _pickDate(end: false),
                          title: Text(
                            'Date',
                            style: TextStyle(color: colours.textPrimary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(color: colours.accent),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 16,
                                color: colours.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_allDay) ...[
                        Divider(height: 1, color: colours.border),
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: _pickTime,
                            title: Text(
                              'Time',
                              style: TextStyle(color: colours.textPrimary),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(color: colours.accent),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: colours.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),

                // Counting Direction
                Text(
                  'COUNTING DIRECTION',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                KairosSegmentedControl<MomentDirection>(
                  items: const <MomentDirection, String>{
                    MomentDirection.down: 'Count Down',
                    MomentDirection.up: 'Count Up',
                    MomentDirection.both: 'Both',
                  },
                  selected: _direction,
                  onChanged: (val) => setState(() => _direction = val),
                ),

                const SizedBox(height: Space.lg),

                // Counter Unit / Format
                Text(
                  'COUNTER FORMAT',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    KairosChoiceChip(
                      label: 'DAYS',
                      selected: _countingMode == CountingMode.days,
                      onSelected: (_) =>
                          setState(() => _countingMode = CountingMode.days),
                    ),
                    KairosChoiceChip(
                      label: 'CONTINUOUS (D H M S)',
                      selected: _countingMode == CountingMode.continuous,
                      onSelected: (_) => setState(
                        () => _countingMode = CountingMode.continuous,
                      ),
                    ),
                    KairosChoiceChip(
                      label: 'HOURS',
                      selected: _countingMode == CountingMode.hours,
                      onSelected: (_) =>
                          setState(() => _countingMode = CountingMode.hours),
                    ),
                    KairosChoiceChip(
                      label: 'MINUTES',
                      selected: _countingMode == CountingMode.minutes,
                      onSelected: (_) =>
                          setState(() => _countingMode = CountingMode.minutes),
                    ),
                    KairosChoiceChip(
                      label: 'SECONDS',
                      selected: _countingMode == CountingMode.seconds,
                      onSelected: (_) =>
                          setState(() => _countingMode = CountingMode.seconds),
                    ),
                  ],
                ),

                const SizedBox(height: Space.lg),

                // Notes Field
                Text(
                  'NOTES',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                const SizedBox(height: Space.sm),
                SurfaceCard(
                  borderRadius: BorderRadius.circular(RadiusTokens.input),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: _notes,
                    maxLines: 4,
                    style: TextStyle(fontSize: 15, color: colours.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Add private thoughts, tickets, or packing notes...',
                      hintStyle: TextStyle(color: colours.textTertiary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(height: Space.md),
              ],
            ),
          ),

          // Sticky Save Button in Thumb Zone
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.md),
            child: PillButton(
              onPressed: _saving ? null : _save,
              label: _editing ? 'Save Changes' : 'Create Moment',
              isLoading: _saving,
              variant: PillButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }
}
