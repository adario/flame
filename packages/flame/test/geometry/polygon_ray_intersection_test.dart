import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:test/test.dart';

void main() {
  test('does not classify an outside vertex hit as inside', () {
    final hitbox = PolygonHitbox([
      Vector2(0, 0),
      Vector2(10, 0),
      Vector2(10, 10),
      Vector2(0, 10),
    ]);

    final result = hitbox.rayIntersection(
      Ray2(origin: Vector2(-1, -1), direction: Vector2(1, 1).normalized()),
    );

    expect(result, isNotNull);
    expect(result!.isInsideHitbox, isFalse);
  });

  test('classifies a concave polygon with multiple crossings correctly', () {
    final hitbox = PolygonHitbox([
      Vector2(0, 0),
      Vector2(4, 0),
      Vector2(4, 4),
      Vector2(3, 4),
      Vector2(3, 1),
      Vector2(1, 1),
      Vector2(1, 4),
      Vector2(0, 4),
    ]);

    final result = hitbox.rayIntersection(
      Ray2(origin: Vector2(0.5, 2), direction: Vector2(1, 0)),
    );

    expect(result, isNotNull);
    expect(result!.isInsideHitbox, isTrue);
  });
}
