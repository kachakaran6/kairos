import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      setState(() => _error = 'Give this moment a title.');
      return;
    }
    if (_endDate != null && !_endDate!.isAfter(_date)) {
      setState(() => _error = 'The end must be after the start.');
      return;
    }
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

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit moment' : 'New moment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          children: <Widget>[
            TextField(
              controller: _title,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _subtitle,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Subtitle (optional)',
              ),
            ),
            const SizedBox(height: Space.sm),
            Text('Category', style: kairos.typeScale.section),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: <Widget>[
                for (final category in MomentCategory.values)
                  ChoiceChip(
                    label: Text(_categoryLabel(category)),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All-day moment'),
              subtitle: const Text('Counts whole days, not hours.'),
              value: _allDay,
              onChanged: (value) => setState(() => _allDay = value),
            ),
            const SizedBox(height: Space.sm),
            _FieldRow(
              label: _allDay ? 'Date' : 'Date and time',
              value: _allDay
                  ? _formatDate(_date)
                  : '${_formatDate(_date)} · ${_formatTime(_date)}',
              onTap: () async {
                await _pickDate();
                if (!_allDay) await _pickTime();
              },
            ),
            const SizedBox(height: Space.sm),
            _FieldRow(
              label: 'Ends (optional)',
              value: _endDate == null ? 'No end date' : _formatDate(_endDate!),
              onTap: () => _pickDate(end: true),
            ),
            if (_endDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text('Clear end date'),
                ),
              ),
            const SizedBox(height: Space.lg),
            Text('Counts', style: kairos.typeScale.section),
            const SizedBox(height: Space.xs),
            SegmentedButton<MomentDirection>(
              segments: const <ButtonSegment<MomentDirection>>[
                ButtonSegment(value: MomentDirection.down, label: Text('Down')),
                ButtonSegment(value: MomentDirection.up, label: Text('Up')),
                ButtonSegment(value: MomentDirection.both, label: Text('Both')),
              ],
              selected: <MomentDirection>{_direction},
              onSelectionChanged: (value) =>
                  setState(() => _direction = value.first),
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: Space.sm),
              Text(
                _error!,
                style: kairos.typeScale.caption.copyWith(
                  color: kairos.colours.danger,
                ),
              ),
            ],
            const SizedBox(height: Space.xl),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save moment'),
            ),
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

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: kairos.typeScale.caption.copyWith(
                      color: kairos.colours.textSecondary,
                    ),
                  ),
                  Text(value, style: kairos.typeScale.body),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kairos.colours.textTertiary),
          ],
        ),
      ),
    );
  }
}
