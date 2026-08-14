import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design_system/motion.dart';

class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.color,
    this.particleCount = 20,
  });

  final Color color;
  final int particleCount;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> {
  final _random = Random();
  late final List<_ParticleConfig> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount.clamp(
        0,
        HabiterMotion.particleBudget(reduced: false),
      ),
      (index) {
        final angle = _random.nextDouble() * 2 * pi;
        final distance = 40.0 + _random.nextDouble() * 100.0;
        final size = 4.0 + _random.nextDouble() * 6.0;
        final opacity = 0.6 + _random.nextDouble() * 0.4;
        return _ParticleConfig(angle, distance, size, opacity);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.reduceMotion;
    if (reduced) return const SizedBox.shrink();
    final duration = HabiterMotion.emphasized.duration(reduced: reduced);
    return Stack(
      alignment: Alignment.center,
      children: _particles.map((p) {
        return Container(
              key: const ValueKey('particle'),
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: p.opacity),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
            .animate()
            .move(
              duration: duration,
              begin: Offset.zero,
              end: Offset(cos(p.angle) * p.distance, sin(p.angle) * p.distance),
              curve: Curves.easeOutCubic,
            )
            .fadeOut(
              delay: HabiterMotion.quick.duration(reduced: reduced),
              duration: HabiterMotion.standard.duration(reduced: reduced),
            )
            .scale(
              duration: duration,
              begin: const Offset(0.2, 0.2),
              end: const Offset(1.0, 1.0),
            );
      }).toList(),
    );
  }
}

class _ParticleConfig {
  final double angle;
  final double distance;
  final double size;
  final double opacity;

  _ParticleConfig(this.angle, this.distance, this.size, this.opacity);
}
