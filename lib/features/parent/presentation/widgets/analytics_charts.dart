import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BaseraRiskLineChart extends StatelessWidget {
  final List<double> weeklyScores;
  final bool isDark;

  const BaseraRiskLineChart({
    super.key,
    required this.weeklyScores,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Trend (Past 7 Days)',
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                scores: weeklyScores.isNotEmpty ? weeklyScores : [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> scores;
  final bool isDark;

  _LineChartPainter({required this.scores, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines
    final double stepY = size.height / 5;
    for (int i = 0; i <= 5; i++) {
      final double y = i * stepY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (scores.isEmpty) return;

    final double stepX = size.width / (scores.length - 1);
    final List<Offset> points = [];

    // Map risk scores (1-10) to Y coordinates
    for (int i = 0; i < scores.length; i++) {
      final double score = scores[i].clamp(1.0, 10.0);
      final double pctY = 1.0 - ((score - 1.0) / 9.0);
      final double x = i * stepX;
      final double y = pctY * size.height;
      points.add(Offset(x, y));
    }

    // Draw gradient fill path
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF6366F1).withValues(alpha: 0.3),
        const Color(0xFF6366F1).withValues(alpha: 0.0),
      ],
    );
    fillPaint.shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw lines
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 5.0, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BaseraCategoryDonutChart extends StatelessWidget {
  final Map<String, int> categoryCounts;
  final bool isDark;

  const BaseraCategoryDonutChart({
    super.key,
    required this.categoryCounts,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = categoryCounts.isNotEmpty && categoryCounts.values.any((v) => v > 0);

    return Container(
      height: 200.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Category Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: hasData
                ? Row(
                    children: [
                      SizedBox(
                        width: 110.w,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _DonutChartPainter(
                            data: categoryCounts,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categoryCounts.entries.map((e) {
                              final color = _getCategoryColor(e.key);
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10.w,
                                      height: 10.h,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        '${e.key}: ${e.value}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.sp,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'No category data available',
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'gambling':
        return const Color(0xFFEF4444);
      case 'pornography':
        return const Color(0xFFB91C1C);
      case 'violence':
        return const Color(0xFFF97316);
      case 'general':
      case 'safe':
      case 'education':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, int> data;

  _DonutChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.values.fold(0, (a, b) => a + b).toDouble();
    if (total == 0) return;

    final double center = min(size.width, size.height) / 2;
    final double innerRadius = center * 0.6;
    final Rect rect = Rect.fromLTWH(0, 0, center * 2, center * 2);

    double startAngle = -pi / 2;

    for (final entry in data.entries) {
      final double sweepAngle = (entry.value / total) * 2 * pi;
      if (sweepAngle == 0) continue;

      final paint = Paint()
        ..color = BaseraCategoryDonutChart._getCategoryColor(entry.key)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Draw inner circle to create donut effect
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
