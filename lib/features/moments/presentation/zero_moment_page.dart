import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../domain/moment.dart';

/// Spec §17: The Zero Moment celebration sequence.
///
/// Triggered when a moment's countdown reaches 00:00:00:00 or previewed
/// from the moment details. Features radiating ripples, confetti burst particles,
/// and sequential haptic progression.
class ZeroMomentPage extends StatefulWidget {
  const ZeroMomentPage({super.key, required this.moment});

  final Moment moment;

  @override
  State<ZeroMomentPage> createState() => _ZeroMomentPageState();
}

class _ZeroMomentPageState extends State<ZeroMomentPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_Particle> _particles = <_Particle>[];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _generateParticles();
    _runCelebrationSequence();
  }

  void _generateParticles() {
    _particles.clear();
    for (var i = 0; i < 48; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 80.0 + _random.nextDouble() * 220.0;
      final size = 3.0 + _random.nextDouble() * 5.0;
      final rotation = _random.nextDouble() * pi;
      _particles.add(
        _Particle(angle: angle, speed: speed, size: size, rotation: rotation),
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

    return Scaffold(
      backgroundColor: kairos.colours.background,
      body: Stack(
        children: <Widget>[
          // Background particle & ripple canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CelebrationPainter(
                    progress: _animController.value,
                    accentColor: kairos.colours.accent,
                    accentMuted: kairos.colours.accentMuted,
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
                vertical: Space.xl,
              ),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kairos.colours.accentMuted,
                      border: Border.all(
                        color: kairos.colours.accent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: kairos.colours.accent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  Text(
                    'The Zero Moment',
                    style: kairos.typeScale.caption.copyWith(
                      color: kairos.colours.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'It is here.',
                    textAlign: TextAlign.center,
                    style: kairos.typeScale.display.copyWith(
                      color: kairos.colours.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    widget.moment.title,
                    textAlign: TextAlign.center,
                    style: kairos.typeScale.title.copyWith(
                      color: kairos.colours.textSecondary,
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
                  const SizedBox(height: Space.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: Space.xs,
                    ),
                    decoration: BoxDecoration(
                      color: kairos.colours.surfaceElevated,
                      borderRadius: RadiusTokens.pillRadius,
                      border: Border.all(color: kairos.colours.border),
                    ),
                    child: Text(
                      'Just transitioned to Then',
                      style: kairos.typeScale.caption.copyWith(
                        color: kairos.colours.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _generateParticles();
                            _runCelebrationSequence();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.sm,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                            minimumSize: const Size.fromHeight(
                              Space.touchTargetAndroid,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: RadiusTokens.mdRadius,
                            ),
                          ),
                          icon: const Icon(Icons.replay),
                          label: const Text('Replay'),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              Space.touchTargetAndroid,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: RadiusTokens.mdRadius,
                            ),
                          ),
                          child: const Text('Continue'),
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

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
  });

  final double angle;
  final double speed;
  final double size;
  final double rotation;
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.progress,
    required this.accentColor,
    required this.accentMuted,
    required this.particles,
  });

  final double progress;
  final Color accentColor;
  final Color accentMuted;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);

    // 1. Draw expanding radial glow ripples
    for (var i = 1; i <= 3; i++) {
      final rippleProgress = ((progress * 1.5) - (i * 0.2)).clamp(0.0, 1.0);
      if (rippleProgress > 0 && rippleProgress < 1.0) {
        final radius = rippleProgress * (size.width * 0.65);
        final opacity = (1.0 - rippleProgress) * 0.45;
        final ripplePaint = Paint()
          ..color = accentColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, radius, ripplePaint);
      }
    }

    // 2. Draw particle burst
    final particleProgress = (progress * 1.8).clamp(0.0, 1.0);
    final particleOpacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final dist = p.speed * particleProgress;
      final px = center.dx + cos(p.angle) * dist;
      final py =
          center.dy +
          sin(p.angle) * dist +
          (particleProgress * 40.0); // subtle gravity

      final pPaint = Paint()
        ..color = accentColor.withValues(alpha: particleOpacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + (progress * 3));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 1.4,
        ),
        pPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
