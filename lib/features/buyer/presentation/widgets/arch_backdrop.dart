import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Home tab's backdrop: a cream arched window (a "jharokha") on a rose
/// pink field. It is drawn in code rather than stretched from a bitmap, so it
/// stays sharp at any size and keeps the arch's proportions: the scalloped
/// top is scaled uniformly with the screen width while the cream body simply
/// runs down to the bottom of whatever height it is given.
///
/// On wide screens (web, tablets) the arch stops growing at [maxArchWidth]
/// and is centred on the pink field instead of being blown up.
class ArchBackdrop extends StatelessWidget {
  const ArchBackdrop({super.key, this.maxArchWidth = 520});

  final double maxArchWidth;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ArchBackdropPainter(maxArchWidth: maxArchWidth),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class ArchBackdropPainter extends CustomPainter {
  const ArchBackdropPainter({required this.maxArchWidth});

  final double maxArchWidth;

  static const _pinkEdge = Color(0xFFED6886);
  static const _pinkMid = Color(0xFFF6869A);
  static const _pinkGlow = Color(0xFFF9A6B4);
  static const _cream = Color(0xFFFCF0DE);
  static const _fibre = Color(0xFFF2DDBE);
  static const _outline = Color(0xFFC4627F);

  /// The artwork's native width; every coordinate below is in this grid and
  /// is scaled uniformly, so the arch never stretches.
  static const _designWidth = 328.0;

  /// The left half of the arch is a stack of five lobes (a multifoil, or
  /// "cusped", arch). Each list is one lobe's curve, running up from one
  /// cusp to the next; the cusps are the sharp points where lobes meet. The
  /// right half is the mirror image.
  static const _wallX = 6.0;
  static const _lobes = <List<Offset>>[
    [
      Offset(5, 228),
      Offset(12, 216),
      Offset(17, 204),
      Offset(18, 192),
      Offset(15, 176),
      Offset(12, 164),
      Offset(20, 151),
    ],
    [
      Offset(20, 151),
      Offset(17, 138),
      Offset(19, 124),
      Offset(26, 112),
      Offset(44, 105),
    ],
    [
      Offset(44, 105),
      Offset(45, 92),
      Offset(54, 78),
      Offset(68, 73),
      Offset(86, 70),
    ],
    [
      Offset(86, 70),
      Offset(90, 60),
      Offset(104, 54),
      Offset(120, 52),
      Offset(131, 57),
    ],
    [
      Offset(131, 57),
      Offset(133, 48),
      Offset(144, 41),
      Offset(156, 38),
      Offset(164, 30),
    ],
  ];

  double _scaleFor(Size size) =>
      (size.width < maxArchWidth ? size.width : maxArchWidth) / _designWidth;

  /// Appends a smooth curve through [points] (Catmull-Rom converted to
  /// cubic Béziers). The first point is where the path already is.
  static void _curveThrough(Path path, List<Offset> points) {
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i == 0 ? 0 : i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 2 < points.length ? i + 2 : i + 1];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
  }

  Path _archPath(Size size) {
    final scale = _scaleFor(size);
    final left = (size.width - _designWidth * scale) / 2;
    Offset at(Offset o) => Offset(left + o.dx * scale, o.dy * scale);
    Offset mirror(Offset o) => Offset(_designWidth - o.dx, o.dy);
    final bottom = size.height + 4;

    final path = Path()
      ..moveTo(at(const Offset(_wallX, 0)).dx, bottom)
      ..lineTo(at(_lobes.first.first).dx, at(_lobes.first.first).dy);
    for (final lobe in _lobes) {
      _curveThrough(path, [for (final o in lobe) at(o)]);
    }
    for (final lobe in _lobes.reversed) {
      _curveThrough(path, [for (final o in lobe.reversed) at(mirror(o))]);
    }
    final rightFoot = at(mirror(_lobes.first.first));
    path
      ..lineTo(rightFoot.dx, bottom)
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleFor(size);
    final field = Offset.zero & size;

    // Rose field, lighter around the arch and deeper towards the edges.
    canvas.drawRect(
      field,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, -0.55),
          radius: 0.95,
          colors: const [_pinkGlow, _pinkMid, _pinkEdge],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(field),
    );

    final arch = _archPath(size);
    canvas.drawPath(arch, Paint()..color = _cream);

    // Faint fibres, like handmade paper. A fixed seed keeps them identical
    // on every paint and for every size.
    canvas.save();
    canvas.clipPath(arch);
    final left = (size.width - _designWidth * scale) / 2;
    final random = math.Random(7);
    final fibrePaint = Paint()
      ..color = _fibre.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1 * scale;
    final rows = (size.height / scale / 14).ceil();
    for (var i = 0; i < rows; i++) {
      final y = (60 + i * 14 + random.nextDouble() * 10) * scale;
      final x = left + (random.nextDouble() * (_designWidth - 80)) * scale;
      final length = (24 + random.nextDouble() * 50) * scale;
      canvas.drawLine(Offset(x, y), Offset(x + length, y), fibrePaint);
    }
    canvas.restore();

    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale
        ..strokeJoin = StrokeJoin.round
        ..color = _outline.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(ArchBackdropPainter oldDelegate) =>
      oldDelegate.maxArchWidth != maxArchWidth;
}
