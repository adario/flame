import 'dart:ui';

import 'package:flame/components.dart';
import 'package:test/test.dart';

void main() {
  test('contour preserves the path bounds', () {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 64, 64),
          const Radius.circular(10),
        ),
      );

    final polygon = PolygonComponent.contour(path);

    expect(polygon.size.x, closeTo(64, 1e-10));
    expect(polygon.size.y, closeTo(64, 1e-10));
    expect(polygon.vertices.first, isNot(polygon.vertices.last));
  });
}
