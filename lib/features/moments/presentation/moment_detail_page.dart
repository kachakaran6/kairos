import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/countdown.dart';
import '../domain/moment.dart';
import '../domain/moment_phase.dart';
import 'moment_controller.dart';
import 'moment_editor_page.dart';

class MomentDetailPage extends ConsumerStatefulWidget {
  const MomentDetailPage({super.key, required this.momentId});

  final String momentId;

  @override
  ConsumerState<MomentDetailPage> createState() => _MomentDetailPageState();
}

class _MomentDetailPageState extends ConsumerState<MomentDetailPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final moments = ref.watch(momentListProvider).value;
    final moment = moments
        ?.where((item) => item.id == widget.momentId)
        .firstOrNull;

    if (moment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Moment not found')),
      );
    }

    final now = ref.read(clockProvider).nowUtc();
    final phase = phaseAt(moment, now);
    final countdown = Countdown.format(now, moment.targetUtc);

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            tooltip: moment.pinned ? 'Unpin' : 'Pin',
            onPressed: () =>
                ref.read(momentListProvider.notifier).togglePinned(moment.id),
            icon: Icon(
              moment.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MomentEditorPage(moment: moment),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              Text(
                moment.title,
                textAlign: TextAlign.center,
                style: kairos.typeScale.section.copyWith(
                  color: kairos.colours.textSecondary,
                ),
              ),
              if (moment.subtitle != null) ...<Widget>[
                const SizedBox(height: Space.xxs),
                Text(
                  moment.subtitle!,
                  textAlign: TextAlign.center,
                  style: kairos.typeScale.caption.copyWith(
                    color: kairos.colours.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: Space.lg),
              switch (phase) {
                NextPhase() => _Hero(
                  value: countdown.value,
                  unit: '${countdown.unit} to go',
                  kairos: kairos,
                ),
                NowPhase(:final dayNumber, :final totalDays, :final fraction) =>
                  Column(
                    children: <Widget>[
                      _Hero(
                        value: '$dayNumber',
                        unit: 'of $totalDays days',
                        kairos: kairos,
                      ),
                      const SizedBox(height: Space.lg),
                      ClipRRect(
                        borderRadius: RadiusTokens.pillRadius,
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: Space.xs,
                          backgroundColor: kairos.colours.accentMuted,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        '${(fraction * 100).floor()}% complete',
                        style: kairos.typeScale.caption.copyWith(
                          color: kairos.colours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ThenPhase() => _Hero(
                  value: countdown.value,
                  unit: '${countdown.unit} since',
                  kairos: kairos,
                ),
              },
              const Spacer(),
              Text(
                _dateLabel(moment),
                textAlign: TextAlign.center,
                style: kairos.typeScale.body.copyWith(
                  color: kairos.colours.textSecondary,
                ),
              ),
              if (moment.notes != null) ...<Widget>[
                const SizedBox(height: Space.md),
                Text(
                  moment.notes!,
                  textAlign: TextAlign.center,
                  style: kairos.typeScale.body,
                ),
              ],
              const SizedBox(height: Space.xl),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete this moment?'),
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
                  if (confirmed == true) {
                    await ref
                        .read(momentListProvider.notifier)
                        .remove(moment.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(Moment moment) {
    final date = moment.targetUtc.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final time = moment.isAllDay
        ? ''
        : ' · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$day/$month/${date.year}$time';
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.value, required this.unit, required this.kairos});

  final String value;
  final String unit;
  final KairosTheme kairos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: kairos.typeScale.display.copyWith(
              color: kairos.colours.textPrimary,
            ),
          ),
        ),
        Text(
          unit,
          style: kairos.typeScale.section.copyWith(
            color: kairos.colours.textSecondary,
          ),
        ),
      ],
    );
  }
}
