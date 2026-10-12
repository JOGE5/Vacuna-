import 'package:flutter/material.dart';
import '../core/theme.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 90,
        child: CustomPaint(
          size: const Size(double.infinity, 90),
          painter: _TrendPainter(),
        ),
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Lun', style: TextStyle(fontSize: 10)),
          Text('Mar', style: TextStyle(fontSize: 10)),
          Text('Mié', style: TextStyle(fontSize: 10)),
          Text('Jue', style: TextStyle(fontSize: 10)),
          Text('Vie', style: TextStyle(fontSize: 10)),
          Text('Sáb', style: TextStyle(fontSize: 10)),
          Text('Dom', style: TextStyle(fontSize: 10)),
        ],
      ),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [.8, .68, .78, .46, .49, .24, .47, .32, .02];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * size.width / (points.length - 1),
          y = points[i] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD9EEDC), Colors.white],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = green
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (var i = 1; i < points.length; i++) {
      canvas.drawCircle(
        Offset(i * size.width / (points.length - 1), points[i] * size.height),
        3,
        Paint()..color = green,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WeeklyBars extends StatelessWidget {
  const WeeklyBars({super.key, this.values = const [100, 120, 110, 150]});
  final List<int> values;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(
          width: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('200', style: TextStyle(fontSize: 10)),
              Text('150', style: TextStyle(fontSize: 10)),
              Text('100', style: TextStyle(fontSize: 10)),
              Text('50', style: TextStyle(fontSize: 10)),
              Text('0', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        ...List.generate(
          values.length,
          (i) => Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${values[i]}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: values[i] * .68,
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: i == 3 ? ink : green.withValues(alpha: .5 + i * .12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Semana ${i + 1}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
