import 'package:flutter/material.dart';

class NavGradientPainter extends CustomPainter {
  NavGradientPainter({
    required this.startingLoc,
    required this.itemsLength,
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.textDirection,
    this.hasLabel = false,
  });

  final double startingLoc;
  final int itemsLength;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final TextDirection textDirection;
  final bool hasLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: gradientBegin,
        end: gradientEnd,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();

    // Calculate width per item
    final itemWidth = size.width / itemsLength;

    // Calculate selected index position
    final loc = startingLoc * itemsLength;

    // Calculate bubble position
    final bubblePos =
        textDirection == TextDirection.rtl ? itemsLength - loc - 1 : loc;

    // Calculate the center of the selected item
    final centerX = itemWidth * bubblePos + (itemWidth / 2);

    // Define curve parameters
    final curveWidth = itemWidth * 0.8; // Width of the curve
    final curveHeight = size.height * 0.6; // How far the curve extends upward

    // Create a blend zone for smooth transition
    final blendZone = itemWidth * 0.5;

    // Start path
    path.moveTo(0, 0);

    // Draw line to the start of the blend zone before the curve
    path.lineTo(centerX - curveWidth / 2 - blendZone, 0);

    // Create a smooth entry into the curve using cubic Bezier
    path.cubicTo(
      centerX - curveWidth / 2 - blendZone / 2, 0, // First control point
      centerX - curveWidth / 2, 0, // Second control point
      centerX - curveWidth / 2, curveHeight * 0.2, // End point of this segment
    );

    // Draw the main circular part using cubic Bezier
    path.cubicTo(
      centerX - curveWidth / 4, curveHeight, // First control point
      centerX + curveWidth / 4, curveHeight, // Second control point
      centerX + curveWidth / 2,
      curveHeight * 0.2, // End point of the main curve
    );

    // Create a smooth exit from the curve using cubic Bezier
    path.cubicTo(
      centerX + curveWidth / 2, 0, // First control point
      centerX + curveWidth / 2 + blendZone / 2, 0, // Second control point
      centerX + curveWidth / 2 + blendZone,
      0, // End point returning to the horizontal
    );

    // Complete the right side of the bar
    path.lineTo(size.width, 0);

    // Complete the path to form the bar
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NavGradientPainter oldDelegate) {
    return oldDelegate.startingLoc != startingLoc ||
        oldDelegate.gradientColors != gradientColors;
  }
}
