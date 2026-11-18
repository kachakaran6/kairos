import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/widget_suite/widget_sync_service.dart';
import 'widget_setup_help_page.dart';

class WidgetDoctorPage extends ConsumerStatefulWidget {
  const WidgetDoctorPage({super.key});

  @override
  ConsumerState<WidgetDoctorPage> createState() => _WidgetDoctorPageState();
}

class _WidgetDoctorPageState extends ConsumerState<WidgetDoctorPage> {
  static const MethodChannel _channel = MethodChannel(
    'com.samyukt.kairos/widget_oem',
  );

  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final res = await _channel.invokeListMethod<dynamic>(
        'getWidgetDoctorStatus',
      );
      if (res != null && mounted) {
        setState(() {
          _providers = res
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forceRefreshAll() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(widgetSyncServiceProvider).syncAllWidgets();
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All 6 home widgets refreshed successfully!'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _formatTimestamp(dynamic millis) {
    if (millis == null || millis == 0) return 'Never updated';
    final dt = DateTime.fromMillisecondsSinceEpoch((millis as num).toInt());
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return KairosScaffold(
      title: 'Widget Doctor',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.helpCircle, size: 20),
          tooltip: 'Widget Setup Help',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WidgetSetupHelpPage(),
              ),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Banner
            SurfaceCard(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colours.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: Icon(
                      LucideIcons.stethoscope,
                      color: colours.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Widget Diagnostics',
                          style: kairos.typeScale.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colours.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Live registration, placement & update integrity',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Space.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APPWIDGET PROVIDERS (6)',
                  style: kairos.typeScale.label.copyWith(
                    color: colours.textTertiary,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),

            for (final p in _providers) ...[
              SurfaceCard(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p['label']?.toString() ?? 'Provider',
                            style: kairos.typeScale.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colours.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (p['isRegistered'] == true)
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              RadiusTokens.pill,
                            ),
                          ),
                          child: Text(
                            (p['isRegistered'] == true)
                                ? 'Registered'
                                : 'Unregistered',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: (p['isRegistered'] == true)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['className']?.toString() ?? '',
                      style: kairos.typeScale.caption.copyWith(
                        fontFamily: 'monospace',
                        color: colours.textTertiary,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.layoutGrid,
                              size: 14,
                              color: colours.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${p['instancesCount'] ?? 0} placed',
                              style: kairos.typeScale.caption.copyWith(
                                color: colours.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: colours.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(p['lastUpdateMillis']),
                              style: kairos.typeScale.caption.copyWith(
                                color: colours.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (p['lastError'] != null && p['lastError'] != 'OK') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Last error: ${p['lastError']}',
                        style: kairos.typeScale.caption.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
            ],

            const SizedBox(height: Space.lg),

            // Actions
            PillButton(
              onPressed: _isRefreshing ? null : _forceRefreshAll,
              label: _isRefreshing
                  ? 'Refreshing...'
                  : 'Force Refresh All Widgets',
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              variant: PillButtonVariant.primary,
            ),
            const SizedBox(height: Space.sm),
            PillButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WidgetSetupHelpPage(),
                  ),
                );
              },
              label: 'Widget Setup & OEM Guide',
              icon: const Icon(LucideIcons.settings2, size: 18),
              variant: PillButtonVariant.secondary,
            ),
            const SizedBox(height: Space.huge),
          ],
        ),
      ),
    );
  }
}
