import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Shield logo (drawn in code, no image assets needed)
// ---------------------------------------------------------------------------
class ShieldLogo extends StatelessWidget {
  const ShieldLogo({super.key, this.size = 56, this.face = false});

  final double size;

  /// true = big splash version with a smiling face, false = badge with a star.
  final bool face;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(painter: _ShieldPainter(face)),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.face);
  final bool face;

  // Drawn in a 100 x 112 box, then scaled to the widget size.
  Path _shield() {
    return Path()
      ..moveTo(50, 2)
      ..cubicTo(62, 12, 78, 16, 94, 16)
      ..lineTo(94, 56)
      ..cubicTo(94, 84, 74, 100, 50, 110)
      ..cubicTo(26, 100, 6, 84, 6, 56)
      ..lineTo(6, 16)
      ..cubicTo(22, 16, 38, 12, 50, 2)
      ..close();
  }

  Path _star(Offset c, double outer, double inner) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 112);
    const box = Rect.fromLTWH(0, 0, 100, 112);
    final path = _shield();

    if (face) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFB9C8FF);
      canvas.save();
      canvas.translate(50, 66);
      canvas.rotate(-0.25);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 124, height: 34), ring);
      canvas.restore();

      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFD6E2FF)],
          ).createShader(box),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF1F3FBF),
      );
      final eye = Paint()..color = const Color(0xFF14275E);
      canvas.drawOval(Rect.fromCenter(center: const Offset(37, 56), width: 8, height: 12), eye);
      canvas.drawOval(Rect.fromCenter(center: const Offset(63, 56), width: 8, height: 12), eye);
      canvas.drawPath(
        Path()
          ..moveTo(40, 70)
          ..quadraticBezierTo(50, 80, 60, 70),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF14275E),
      );
      final blush = Paint()..color = const Color(0x66FF8FA3);
      canvas.drawCircle(const Offset(28, 68), 5, blush);
      canvas.drawCircle(const Offset(72, 68), 5, blush);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B86FF), Color(0xFF1E3FC4)],
          ).createShader(box),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFBFD0FF),
      );
      canvas.drawPath(_star(const Offset(50, 58), 24, 10), Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter old) => old.face != face;
}

// ---------------------------------------------------------------------------
// Sparkline
// ---------------------------------------------------------------------------
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color = kSafe, this.height = 70});

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final vals = values.isEmpty ? <double>[100, 100] : (values.length == 1 ? [values.first, values.first] : values);
    var minV = vals.reduce(math.min);
    var maxV = vals.reduce(math.max);
    if (maxV - minV < 4) {
      final mid = (maxV + minV) / 2;
      minV = mid - 2;
      maxV = mid + 2;
    }
    final n = vals.length;
    final dx = size.width / (n - 1);
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(i * dx, size.height - 6 - ((vals[i] - minV) / (maxV - minV)) * (size.height - 12)),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < n; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.soft(0.35), color.soft(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    canvas.drawCircle(pts.last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(pts.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}

// ---------------------------------------------------------------------------
// Risk graph: you in the center, every scan is a node around you.
// ---------------------------------------------------------------------------
class GraphNode {
  const GraphNode(this.pos, this.radius, this.item);
  final Offset pos;
  final double radius;
  final HistoryItem item;
}

List<GraphNode> layoutGraph(Size size, List<HistoryItem> items) {
  final c = size.center(Offset.zero);
  final maxR = math.min(size.width, size.height) / 2 - 14;
  final n = items.length;
  const golden = 2.399963; // golden angle spreads nodes evenly
  return [
    for (var i = 0; i < n; i++)
      GraphNode(
        c +
            Offset.fromDirection(
              i * golden,
              maxR * (0.34 + 0.66 * math.sqrt((i + 0.5) / n)),
            ),
        switch (items[i].level) {
          'danger' => 8.5,
          'warning' => 7.0,
          _ => 5.5,
        },
        items[i],
      ),
  ];
}

Color graphColor(String level) => switch (level) {
      'danger' => kDanger,
      'warning' => kWarning,
      _ => kGraphSafe,
    };

class RiskGraph extends StatelessWidget {
  const RiskGraph({super.key, required this.items, this.onTap});

  final List<HistoryItem> items;
  final ValueChanged<HistoryItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return LayoutBuilder(
      builder: (context, cons) {
        final side = cons.maxWidth;
        final size = Size(side, side);
        final nodes = layoutGraph(size, items);
        return GestureDetector(
          onTapUp: (d) {
            GraphNode? best;
            var bestDist = 22.0;
            for (final nd in nodes) {
              final dist = (nd.pos - d.localPosition).distance;
              if (dist < bestDist) {
                bestDist = dist;
                best = nd;
              }
            }
            if (best != null) onTap?.call(best.item);
          },
          child: CustomPaint(size: size, painter: _GraphPainter(nodes, p)),
        );
      },
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.nodes, this.palette);
  final List<GraphNode> nodes;
  final Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);

    // faint rings
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = kPrimary.soft(0.10);
    final maxR = math.min(size.width, size.height) / 2 - 14;
    for (final f in [0.4, 0.7, 1.0]) {
      canvas.drawCircle(c, maxR * f, ring);
    }

    // spokes
    for (final n in nodes) {
      canvas.drawLine(
        c,
        n.pos,
        Paint()
          ..strokeWidth = 1
          ..color = graphColor(n.item.level).soft(0.35),
      );
    }

    // nodes
    for (final n in nodes) {
      final col = graphColor(n.item.level);
      canvas.drawCircle(n.pos, n.radius + 3, Paint()..color = col.soft(0.18));
      canvas.drawCircle(n.pos, n.radius, Paint()..color = col);
      canvas.drawCircle(
        n.pos,
        n.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.card,
      );
    }

    // center "you" node
    canvas.drawCircle(c, 34, Paint()..color = kPrimary.soft(0.14));
    canvas.drawCircle(c, 26, Paint()..color = kPrimary);
    canvas.drawCircle(c, 26, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white);
    canvas.drawCircle(c + const Offset(0, -6), 5.5, Paint()..color = Colors.white);
    canvas.drawArc(
      Rect.fromCenter(center: c + const Offset(0, 11), width: 22, height: 16),
      math.pi,
      math.pi,
      true,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => old.nodes != nodes || old.palette.dark != palette.dark;
}
