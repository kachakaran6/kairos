import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
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
  bool _saving = false;
  String? _error;

  bool get _editing => widget.moment != null;

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
        notes: _notes.text,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Scaffold(
      backgroundColor: colours.background,
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit Moment' : 'New Moment',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colours.textPrimary,
          ),
        ),
        backgroundColor: colours.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colours.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colours.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.md,
          ),
          children: <Widget>[
            // Group: Title & Subtitle
            _GroupedCard(
              children: [
                TextField(
                  controller: _title,
                  maxLength: 60,
                  style: TextStyle(fontSize: 17, color: colours.textPrimary),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'What are you counting to?',
                    hintStyle: TextStyle(color: colours.textTertiary),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                Divider(height: 1, color: colours.border),
                TextField(
                  controller: _subtitle,
                  maxLength: 80,
                  style: TextStyle(fontSize: 14, color: colours.textSecondary),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Subtitle or description (optional)',
                    hintStyle: TextStyle(color: colours.textTertiary),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),

            // Group: Category selection
            _SectionLabel(title: 'CATEGORY'),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: <Widget>[
                for (final category in MomentCategory.values)
                  ChoiceChip(
                    label: Text(_categoryLabel(category)),
                    selected: _category == category,
                    selectedColor: colours.accent.withValues(alpha: 0.2),
                    backgroundColor: colours.surface,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: _category == category ? FontWeight.w600 : FontWeight.normal,
                      color: _category == category ? colours.accent : colours.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      side: BorderSide(
                        color: _category == category ? colours.accent : colours.border,
                      ),
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _category = category);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),

            // Group: Date & Time configuration
            _SectionLabel(title: 'SCHEDULE'),
            _GroupedCard(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    'All-day moment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colours.textPrimary),
                  ),
                  subtitle: Text(
                    'Counts calendar days rather than hours',
                    style: TextStyle(fontSize: 13, color: colours.textTertiary),
                  ),
                  activeTrackColor: colours.accent,
                  value: _allDay,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _allDay = value);
                  },
                ),
                Divider(height: 1, color: colours.border),
                _GroupedActionRow(
                  label: _allDay ? 'Date' : 'Date and time',
                  value: _allDay
                      ? _formatDate(_date)
                      : '${_formatDate(_date)} · ${_formatTime(_date)}',
                  onTap: () async {
                    await _pickDate();
                    if (!_allDay) await _pickTime();
                  },
                ),
                Divider(height: 1, color: colours.border),
                _GroupedActionRow(
                  label: 'Ends (optional)',
                  value: _endDate == null ? 'No end date' : _formatDate(_endDate!),
                  onTap: () => _pickDate(end: true),
                ),
              ],
            ),
            if (_endDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _endDate = null);
                    },
                    child: Text('Clear end date', style: TextStyle(color: colours.danger, fontSize: 13)),
                  ),
                ),
              ),
            const SizedBox(height: Space.lg),

            // Group: Counting Direction
            _SectionLabel(title: 'COUNTING MODE'),
            SegmentedButton<MomentDirection>(
              style: SegmentedButton.styleFrom(
                backgroundColor: colours.surface,
                selectedBackgroundColor: colours.accent.withValues(alpha: 0.16),
                selectedForegroundColor: colours.accent,
                foregroundColor: colours.textSecondary,
                side: BorderSide(color: colours.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
              ),
              segments: const <ButtonSegment<MomentDirection>>[
                ButtonSegment(value: MomentDirection.down, label: Text('Count down')),
                ButtonSegment(value: MomentDirection.up, label: Text('Count up')),
                ButtonSegment(value: MomentDirection.both, label: Text('Both')),
              ],
              selected: <MomentDirection>{_direction},
              onSelectionChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _direction = value.first);
              },
            ),
            const SizedBox(height: Space.lg),

            // Group: Notes
            _SectionLabel(title: 'PERSONAL NOTES'),
            _GroupedCard(
              children: [
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: colours.textPrimary),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add thoughts, memory details, or milestones...',
                    hintStyle: TextStyle(color: colours.textTertiary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),

            if (_error != null) ...<Widget>[
              const SizedBox(height: Space.md),
              Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: colours.danger, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: Space.huge),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  static String _categoryLabel(MomentCategory category) {
    switch (category) {
      case MomentCategory.birthday:
        return 'Birthday';
      case MomentCategory.exam:
        return 'Exam';
      case MomentCategory.travel:
        return 'Travel';
      case MomentCategory.work:
        return 'Work';
      case MomentCategory.health:
        return 'Health';
      case MomentCategory.festival:
        return 'Festival';
      case MomentCategory.memorial:
        return 'Memorial';
      case MomentCategory.custom:
        return 'Custom';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colours = KairosTheme.of(context).colours;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: Space.xs),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colours.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colours = KairosTheme.of(context).colours;
    return Container(
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(color: colours.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _GroupedActionRow extends StatelessWidget {
  const _GroupedActionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = KairosTheme.of(context).colours;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colours.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: colours.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: colours.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
