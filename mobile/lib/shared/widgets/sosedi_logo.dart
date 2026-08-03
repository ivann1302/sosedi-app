import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SosediLogo extends StatelessWidget {
  const SosediLogo({
    super.key,
    this.markSize = 32,
    this.showWordmark = true,
    this.markColor = AppColors.brand500,
    this.textColor = AppColors.ink900,
  });

  final double markSize;
  final bool showWordmark;
  final Color markColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Соседи',
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size.square(markSize),
            painter: _SosediMarkPainter(color: markColor),
          ),
          if (showWordmark) ...[
            SizedBox(width: markSize * 0.32),
            Text(
              'Соседи',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SosediMarkPainter extends CustomPainter {
  const _SosediMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(size.width * 0.14, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.09,
        size.height * 0.37,
        size.width * 0.15,
        size.height * 0.31,
      )
      ..lineTo(size.width * 0.42, size.height * 0.07)
      ..quadraticBezierTo(
        size.width * 0.50,
        0,
        size.width * 0.58,
        size.height * 0.07,
      )
      ..lineTo(size.width * 0.85, size.height * 0.31)
      ..quadraticBezierTo(
        size.width * 0.91,
        size.height * 0.37,
        size.width * 0.86,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.83,
        size.height * 0.45,
        size.width * 0.78,
        size.height * 0.47,
      )
      ..lineTo(size.width * 0.78, size.height * 0.87)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.94,
        size.width * 0.70,
        size.height * 0.94,
      )
      ..lineTo(size.width * 0.30, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.94,
        size.width * 0.22,
        size.height * 0.87,
      )
      ..lineTo(size.width * 0.22, size.height * 0.47)
      ..quadraticBezierTo(
        size.width * 0.17,
        size.height * 0.45,
        size.width * 0.14,
        size.height * 0.42,
      )
      ..close()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.49),
          radius: size.width * 0.19,
        ),
      );

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SosediMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
