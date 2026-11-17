import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/colour_tokens.dart';
import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/ecosystem/play_update_service.dart';
import '../../../core/ecosystem/samyukt_registry_service.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';

class OurAppsPage extends ConsumerStatefulWidget {
  const OurAppsPage({super.key});

  @override
  ConsumerState<OurAppsPage> createState() => _OurAppsPageState();
}

class _OurAppsPageState extends ConsumerState<OurAppsPage> {
  late Future<SamyuktRegistryResult> _registryFuture;

  @override
  void initState() {
    super.initState();
    _loadCatalog(forceRefresh: false);
  }

  void _loadCatalog({required bool forceRefresh}) {
    _registryFuture = ref
        .read(samyuktRegistryServiceProvider)
        .fetchAppsCatalog(forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return KairosScaffold(
      title: 'Our Apps',
      showBackButton: true,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'Refresh catalog',
          icon: Icon(
            LucideIcons.refreshCw,
            size: 20,
            color: colours.textPrimary,
          ),
          onPressed: () {
            setState(() {
              _loadCatalog(forceRefresh: true);
            });
          },
        ),
      ],
      body: FutureBuilder<SamyuktRegistryResult>(
        future: _registryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colours.accent,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.cloudOff,
                      size: 40,
                      color: colours.textSecondary,
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      'Unable to reach registry',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colours.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'Please check your internet connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: colours.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    PillButton(
                      label: 'Try Again',
                      icon: const Icon(LucideIcons.rotateCcw, size: 18),
                      height: 48,
                      onPressed: () {
                        setState(() {
                          _loadCatalog(forceRefresh: true);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final result = snapshot.data!;
          final apps = result.apps;

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.packageOpen,
                    size: 40,
                    color: colours.textSecondary,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'No applications currently available',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colours.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: colours.accent,
            backgroundColor: colours.surface,
            onRefresh: () async {
              setState(() {
                _loadCatalog(forceRefresh: true);
              });
              await _registryFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              itemCount: apps.length + (result.isFromCache ? 2 : 1),
              separatorBuilder: (_, __) => const SizedBox(height: Space.md),
              itemBuilder: (context, index) {
                // If offline and from cache, show subtle top notice
                if (result.isFromCache && index == 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: Space.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colours.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                      border: Border.all(
                        color: colours.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, size: 16, color: colours.accent),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(
                            'Offline catalog — showing cached registry',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: colours.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final appIndex = result.isFromCache ? index - 1 : index;

                // Footer attribution at the end
                if (appIndex == apps.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xl),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(playServicesBridgeProvider)
                              .openUrl('https://samyukt.pro');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Made with care by ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: colours.textSecondary,
                              ),
                            ),
                            Text(
                              'Samyukt',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colours.accent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final app = apps[appIndex];
                return _buildAppCard(context, colours, app);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    KairosColourTokens colours,
    SamyuktAppItem app,
  ) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: colours.surface,
                    child: app.iconUrl.isNotEmpty
                        ? Image.network(
                            app.iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              LucideIcons.smartphone,
                              size: 26,
                              color: colours.textSecondary,
                            ),
                          )
                        : Icon(
                            LucideIcons.smartphone,
                            size: 26,
                            color: colours.textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colours.textPrimary,
                        ),
                      ),
                      if (app.category != null && app.category!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          app.category!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: colours.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                _buildStatusBadge(colours, app.status),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              app.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.35,
                color: colours.textSecondary,
              ),
            ),
            const SizedBox(height: Space.md),
            Align(
              alignment: Alignment.centerRight,
              child: app.isPublished
                  ? PillButton(
                      label: 'View App',
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      height: 42,
                      width: 140,
                      onPressed: () {
                        if (app.playStoreUrl.isNotEmpty) {
                          ref
                              .read(playServicesBridgeProvider)
                              .openUrl(app.playStoreUrl);
                        } else if (app.packageName.isNotEmpty) {
                          ref
                              .read(playServicesBridgeProvider)
                              .openPlayStoreListing(
                                packageName: app.packageName,
                              );
                        }
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colours.surface,
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                        border: Border.all(color: colours.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: colours.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colours.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    KairosColourTokens colours,
    SamyuktAppStatus status,
  ) {
    final isPub = status == SamyuktAppStatus.published;
    final color = isPub ? colours.accent : colours.textSecondary;
    final label = isPub ? 'Published' : 'Coming Soon';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
