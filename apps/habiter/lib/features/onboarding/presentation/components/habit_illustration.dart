import 'package:flutter/material.dart';

import '../../application/onboarding_state.dart';
import '../onboarding_editorial.dart';

enum HabitIllustrationKind {
  sprout,
  footsteps,
  garden,
  reminder,
  widget,
  growth,
}

class HabitIllustration extends StatelessWidget {
  const HabitIllustration({
    super.key,
    required this.kind,
    required this.step,
    required this.semanticLabel,
    this.height = 210,
  });

  final HabitIllustrationKind kind;
  final OnboardingStep step;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingEditorial.colorsFor(context, step);
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            key: ValueKey<String>('habit-illustration-${kind.name}'),
            painter: HabitIllustrationPainter(
              kind: kind,
              ink: colors.ink,
              accent: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
final class HabitIllustrationPainter extends CustomPainter {
  const HabitIllustrationPainter({
    required this.kind,
    required this.ink,
    required this.accent,
  });

  final HabitIllustrationKind kind;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 260).clamp(0.35, 1.45).toDouble();
    final artworkHeight = 190 * scale;
    canvas.save();
    canvas.translate(
      (size.width - 260 * scale) / 2,
      (size.height - artworkHeight) / 2,
    );
    canvas.scale(scale);

    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fine = Paint()
      ..color = ink.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final wash = Paint()
      ..color = accent.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final fill = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(37, 143)
        ..cubicTo(42, 76, 88, 35, 151, 39)
        ..cubicTo(218, 43, 238, 97, 216, 151)
        ..cubicTo(179, 178, 79, 177, 37, 143)
        ..close(),
      wash,
    );

    switch (kind) {
      case HabitIllustrationKind.sprout:
        _sprout(canvas, line, fine, fill);
      case HabitIllustrationKind.footsteps:
        _footsteps(canvas, line, fine, fill);
      case HabitIllustrationKind.garden:
        _garden(canvas, line, fine, fill);
      case HabitIllustrationKind.reminder:
        _reminder(canvas, line, fine, fill);
      case HabitIllustrationKind.widget:
        _widget(canvas, line, fine, fill);
      case HabitIllustrationKind.growth:
        _growth(canvas, line, fine, fill);
    }
    canvas.restore();
  }

  void _sprout(Canvas canvas, Paint line, Paint fine, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(54, 150)
        ..cubicTo(94, 140, 166, 142, 211, 151),
      line,
    );
    canvas.drawOval(const Rect.fromLTWH(113, 126, 34, 24), line);
    canvas.drawPath(
      Path()
        ..moveTo(130, 129)
        ..cubicTo(127, 108, 132, 88, 143, 73),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(140, 88)
        ..cubicTo(113, 87, 101, 73, 103, 56)
        ..cubicTo(126, 55, 143, 68, 140, 88)
        ..close(),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(142, 75)
        ..cubicTo(147, 51, 165, 40, 185, 44)
        ..cubicTo(184, 64, 164, 78, 142, 75)
        ..close(),
      line,
    );
    canvas.drawCircle(const Offset(64, 126), 4, fill);
    canvas.drawCircle(const Offset(191, 127), 3, fill);
    canvas.drawLine(const Offset(83, 72), const Offset(72, 60), fine);
    canvas.drawLine(const Offset(199, 82), const Offset(215, 74), fine);
    canvas.drawLine(const Offset(151, 31), const Offset(152, 18), fine);
  }

  void _footsteps(Canvas canvas, Paint line, Paint fine, Paint fill) {
    final first = Path()
      ..moveTo(74, 130)
      ..cubicTo(63, 119, 66, 97, 81, 84)
      ..cubicTo(94, 73, 107, 77, 109, 90)
      ..cubicTo(111, 105, 89, 137, 74, 130)
      ..close();
    final second = Path()
      ..moveTo(148, 91)
      ..cubicTo(140, 75, 151, 53, 169, 45)
      ..cubicTo(183, 39, 194, 48, 192, 61)
      ..cubicTo(190, 77, 157, 105, 148, 91)
      ..close();
    canvas.drawPath(first, line);
    canvas.drawPath(second, line);
    canvas.drawOval(const Rect.fromLTWH(59, 139, 22, 13), fill);
    canvas.drawOval(const Rect.fromLTWH(137, 103, 23, 13), fill);
    canvas.drawLine(const Offset(77, 104), const Offset(96, 112), fine);
    canvas.drawLine(const Offset(163, 67), const Offset(184, 72), fine);
    canvas.drawLine(const Offset(49, 81), const Offset(32, 73), fine);
    canvas.drawLine(const Offset(58, 61), const Offset(48, 47), fine);
    canvas.drawLine(const Offset(205, 108), const Offset(223, 97), fine);
  }

  void _garden(Canvas canvas, Paint line, Paint fine, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(54, 58, 154, 100),
        const Radius.circular(16),
      ),
      line,
    );
    canvas.drawLine(const Offset(54, 88), const Offset(208, 88), line);
    canvas.drawLine(const Offset(89, 47), const Offset(89, 69), line);
    canvas.drawLine(const Offset(173, 47), const Offset(173, 69), line);
    for (final x in <double>[82, 130, 178]) {
      canvas.drawLine(Offset(x, 143), Offset(x, 112), fine);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 8, 115), width: 18, height: 10),
        line,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 8, 105), width: 18, height: 10),
        line,
      );
      canvas.drawCircle(Offset(x, 143), 3, fill);
    }
  }

  void _reminder(Canvas canvas, Paint line, Paint fine, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(74, 128)
        ..quadraticBezierTo(91, 116, 91, 85)
        ..cubicTo(91, 39, 165, 39, 170, 85)
        ..quadraticBezierTo(172, 116, 190, 128)
        ..close(),
      line,
    );
    canvas.drawLine(const Offset(69, 129), const Offset(195, 129), line);
    canvas.drawArc(const Rect.fromLTWH(113, 127, 36, 25), 0, 3.14, false, line);
    canvas.drawCircle(const Offset(174, 108), 35, Paint()..color = accent);
    canvas.drawCircle(const Offset(174, 108), 35, line);
    canvas.drawLine(const Offset(174, 108), const Offset(174, 89), line);
    canvas.drawLine(const Offset(174, 108), const Offset(188, 116), line);
    canvas.drawCircle(const Offset(174, 108), 4, fill);
    canvas.drawLine(const Offset(63, 66), const Offset(48, 54), fine);
    canvas.drawLine(const Offset(205, 68), const Offset(219, 56), fine);
  }

  void _widget(Canvas canvas, Paint line, Paint fine, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, 30, 112, 145),
        const Radius.circular(22),
      ),
      line,
    );
    canvas.drawLine(const Offset(116, 43), const Offset(145, 43), fine);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(87, 68, 86, 64),
        const Radius.circular(14),
      ),
      line,
    );
    canvas.drawCircle(const Offset(108, 96), 9, line);
    canvas.drawPath(
      Path()
        ..moveTo(103, 96)
        ..lineTo(108, 101)
        ..lineTo(117, 90),
      fine,
    );
    canvas.drawLine(const Offset(128, 89), const Offset(160, 89), fine);
    canvas.drawLine(const Offset(128, 104), const Offset(151, 104), fine);
    canvas.drawCircle(const Offset(130, 155), 4, fill);
    canvas.drawLine(const Offset(57, 76), const Offset(43, 67), fine);
    canvas.drawLine(const Offset(202, 119), const Offset(220, 113), fine);
  }

  void _growth(Canvas canvas, Paint line, Paint fine, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(48, 153)
        ..lineTo(91, 153)
        ..lineTo(91, 130)
        ..lineTo(132, 130)
        ..lineTo(132, 104)
        ..lineTo(174, 104)
        ..lineTo(174, 78)
        ..lineTo(216, 78),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(174, 78)
        ..cubicTo(169, 58, 173, 39, 184, 27),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(181, 44)
        ..cubicTo(158, 45, 147, 34, 149, 20)
        ..cubicTo(167, 18, 182, 28, 181, 44)
        ..close(),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(184, 31)
        ..cubicTo(190, 13, 207, 7, 222, 13)
        ..cubicTo(218, 29, 201, 37, 184, 31)
        ..close(),
      line,
    );
    canvas.drawCircle(const Offset(70, 143), 4, fill);
    canvas.drawCircle(const Offset(111, 119), 4, fill);
    canvas.drawCircle(const Offset(153, 93), 4, fill);
    canvas.drawLine(const Offset(49, 103), const Offset(35, 96), fine);
  }

  @override
  bool shouldRepaint(covariant HabitIllustrationPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent;
}
