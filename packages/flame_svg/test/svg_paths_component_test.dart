import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter_test/flutter_test.dart';

PathHitbox _hitboxOf(String path, String style) {
  final svg = SvgPaths(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"> '
    '<path d="$path" $style/> </svg>',
  );
  final component = SvgPathsComponent(svg);
  return component.children
      .whereType<PathComponent>()
      .single
      .children
      .whereType<PathHitbox>()
      .single;
}

void main() {
  group('SvgPathsComponent', () {
    test('closes the open contours of filled paths for the hitbox', () {
      final hitbox = _hitboxOf('M0 0L50 0L50 50', 'fill="#ff0000"');
      expect(hitbox.polygons.length, 1);
      expect(hitbox.containsLocalPoint(Vector2(40, 10)), isTrue);
    });

    test('closes the open contours of filled and stroked paths', () {
      final hitbox = _hitboxOf(
        'M0 0L50 0L50 50',
        'fill="#ff0000" stroke="#000000" stroke-width="2"',
      );
      expect(hitbox.polygons.length, 1);
    });

    test('does not create polygons for open stroked paths', () {
      final hitbox = _hitboxOf(
        'M0 0L50 0L50 50',
        'fill="none" stroke="#000000" stroke-width="2"',
      );
      expect(hitbox.polygons, isEmpty);
    });
  });
}
