import 'package:flutter/material.dart';

class MiniTrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> trendData;
  final int minScore;
  final int maxScore;
  final int scoreRange;
  final Color currentColor;

  MiniTrendChartPainter({
    required this.trendData,
    required this.minScore,
    required this.maxScore,
    required this.scoreRange,
    required this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trendData.isEmpty) return;

    final paint = Paint()
      ..color = currentColor.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = currentColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;

    final currentPointPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;

    // Calculate points
    final points = <Offset>[];
    final stepX = size.width / (trendData.length - 1);

    for (int i = 0; i < trendData.length; i++) {
      final score = trendData[i]['score'] as int;
      final x = i * stepX;
      final normalizedScore =
          scoreRange > 0 ? (score - minScore) / scoreRange : 0.5;
      final y = size.height - (normalizedScore * size.height);
      points.add(Offset(x, y));
    }

    // Draw gradient fill under the line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw connecting lines
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isCurrentPoint = i == points.length - 1;

      if (isCurrentPoint) {
        // Draw larger point for current score
        canvas.drawCircle(point, 5, currentPointPaint);
        canvas.drawCircle(
          point,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        // Draw smaller points for historical scores
        canvas.drawCircle(point, 3, pointPaint);
      }
    }

    // Draw score labels for min, max, and current
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Current score label
    if (points.isNotEmpty) {
      final currentPoint = points.last;
      final currentScore = trendData.last['score'] as int;

      textPainter.text = TextSpan(
        text: currentScore.toString(),
        style: TextStyle(
          color: currentColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final labelX = currentPoint.dx - textPainter.width / 2;
      final labelY = currentPoint.dy - textPainter.height - 8;

      // Draw background for label
      final labelRect = Rect.fromLTWH(
        labelX - 4,
        labelY - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = currentColor.withValues(alpha: 0.1),
      );

      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
