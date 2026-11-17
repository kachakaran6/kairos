import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/elevation_tokens.dart';
import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/moment.dart';

/// Spec §17: The Zero Moment celebration sequence.
///
/// Triggered when a moment's countdown reaches 00:00:00:00 or previewed
/// from the moment details. Features a warm radial light bloom, golden/terracotta
/// floating confetti particles, editorial Fraunces typography, and sequential haptics.
class ZeroMomentPage extends StatefulWidget {
  const ZeroMomentPage({super.key, required this.moment});

  final Moment moment;

  @override
  State<ZeroMomentPage> createState() => _ZeroMomentPageState();
}

class _ZeroMomentPageState extends State<ZeroMomentPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_CelebrationParticle> _particles = <_CelebrationParticle>[];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _generateParticles();
    _runCelebrationSequence();
  }

  void _generateParticles() {
    _particles.clear();
    for (var i = 0; i < 64; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 60.0 + _random.nextDouble() * 240.0;
      final size = 3.5 + _random.nextDouble() * 6.0;
      final rotation = _random.nextDouble() * pi;
      final isAccent = _random.nextBool();
      _particles.add(
        _CelebrationParticle(
          angle: angle,
          speed: speed,
          size: size,
          rotation: rotation,
          isAccent: isAccent,
        ),
      );
    }
  }

  Future<void> _runCelebrationSequence() async {
    _animController.forward(from: 0.0);

    // Haptic progression per spec §17
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 240));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    await HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final isDark = kairos.colours.isDark;

    return Scaffold(
      backgroundColor: kairos.colours.background,
      body: Stack(
        children: <Widget>[
          // Background ambient light bloom and confetti canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CelebrationPainter(
                    progress: _animController.value,
                    accentColor: kairos.colours.accent,
                    accentMuted: kairos.colours.accentMuted,
                    isDark: isDark,
                    particles: _particles,
                  ),
                );
              },
            ),
          ),

          // Content overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.phoneMargin,
                vertical: Space.lg,
              ),
              child: Column(
                children: <Widget>[
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: kairos.colours.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Radiating emblem badge
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kairos.colours.accentMuted,
                      border: Border.all(
                        color: kairos.colours.accent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kairos.colours.accent.withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.sparkles,
                        color: kairos.colours.accent,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(height: Space.xl),

                  // Tag label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kairos.colours.surface,
                      borderRadius: RadiusTokens.pillRadius,
                      border: Border.all(color: kairos.colours.border),
                    ),
                    child: Text(
                      'THE ZERO MOMENT',
                      style: kairos.typeScale.caption.copyWith(
                        color: kairos.colours.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: Space.md),

                  // "It is here." in editorial Fraunces serif
                  Text(
                    'It is here.',
                    textAlign: TextAlign.center,
                    style: kairos.typeScale.serifDisplay.copyWith(
                      fontSize: 56,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                      color: kairos.colours.textPrimary,
                    ),
                  ),

                  const SizedBox(height: Space.sm),

                  // Moment title in refined typography
                  Text(
                    widget.moment.title,
                    textAlign: TextAlign.center,
                    style: kairos.typeScale.title.copyWith(
                      color: kairos.colours.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),

                  if (widget.moment.subtitle != null) ...<Widget>[
                    const SizedBox(height: Space.xxs),
                    Text(
                      widget.moment.subtitle!,
                      textAlign: TextAlign.center,
                      style: kairos.typeScale.caption.copyWith(
                        color: kairos.colours.textTertiary,
                      ),
                    ),
                  ],

                  const SizedBox(height: Space.xl),

                  // Transition notice card
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.lg,
                      vertical: Space.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          LucideIcons.history,
                          size: 16,
                          color: kairos.colours.accent,
                        ),
                        const SizedBox(width: Space.sm),
                        Flexible(
                          child: Text(
                            'Now counting forward in Then',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kairos.typeScale.caption.copyWith(
                              color: kairos.colours.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom action buttons
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: PillButton(
                          label: 'Replay',
                          icon: const Icon(LucideIcons.rotateCcw, size: 18),
                          variant: PillButtonVariant.secondary,
                          onPressed: () {
                            _generateParticles();
                            _runCelebrationSequence();
                          },
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: PillButton(
                          label: 'Continue',
                          icon: const Icon(LucideIcons.arrowRight, size: 18),
                          variant: PillButtonVariant.primary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationParticle {
  const _CelebrationParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.isAccent,
  });

  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final bool isAccent;
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.progress,
    required this.accentColor,
    required this.accentMuted,
    required this.isDark,
    required this.particles,
  });

  final double progress;
  final Color accentColor;
  final Color accentMuted;
  final bool isDark;
  final List<_CelebrationParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    // Expanding soft radial light bloom
    final bloomOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.35;
    final bloomRadius = 80.0 + progress * 260.0;
    final bloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: bloomOpacity),
          accentColor.withValues(alpha: bloomOpacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: bloomRadius));

    canvas.drawCircle(center, bloomRadius, bloomPaint);

    // Radiating subtle rings
    for (var i = 1; i <= 3; i++) {
      final ringProgress = (progress * 1.5 - i * 0.18).clamp(0.0, 1.0);
      if (ringProgress > 0 && ringProgress < 1.0) {
        final ringRadius = ringProgress * (size.width * 0.7);
        final ringOpacity = (1.0 - ringProgress) * 0.25;
        final ringPaint = Paint()
          ..color = accentColor.withValues(alpha: ringOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(center, ringRadius, ringPaint);
      }
    }

    // Particle burst
    final particleProgress = (progress * 1.4).clamp(0.0, 1.0);
    final particleOpacity = (1.0 - particleProgress).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.speed * particleProgress;
      // Gentle gravity arc
      final dx = center.dx + cos(p.angle) * distance;
      final dy =
          center.dy + sin(p.angle) * distance + (particleProgress * 35.0);

      final color = p.isAccent
          ? accentColor.withValues(alpha: particleOpacity * 0.9)
          : (isDark
                ? Colors.white.withValues(alpha: particleOpacity * 0.8)
                : ElevationTokens.goldCelebration.withValues(
                    alpha: particleOpacity * 0.85,
                  ));

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + particleProgress * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.4,
            height: p.size * 0.8,
          ),
          const Radius.circular(2.0),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
