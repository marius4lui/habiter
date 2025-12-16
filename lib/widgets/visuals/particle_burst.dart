import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    _particles = List.generate(widget.particleCount, (index) {
      final angle = _random.nextDouble() * 2 * pi;
      final distance = 40.0 + _random.nextDouble() * 100.0;
      final size = 4.0 + _random.nextDouble() * 6.0;
      return _ParticleConfig(angle, distance, size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: _particles.map((p) {
        return Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.6 + _random.nextDouble() * 0.4),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
        )
            .animate()
            .move(
              duration: 600.ms,
              begin: Offset.zero,
              end: Offset(cos(p.angle) * p.distance, sin(p.angle) * p.distance),
              curve: Curves.easeOutCubic,
            )
            .fadeOut(
              delay: 200.ms,
              duration: 400.ms,
            )
            .scale(
              duration: 600.ms,
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

  _ParticleConfig(this.angle, this.distance, this.size);
}
