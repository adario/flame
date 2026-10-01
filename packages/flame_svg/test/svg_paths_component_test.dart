import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter_test/flutter_test.dart';

SvgPathsComponent _componentOf(
  List<(String, String)> paths, {
  SvgHitboxes hitboxes = SvgHitboxes.single,
}) {
  final buffer = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"> ',
  );
  for (final (path, style) in paths) {
    buffer.write('<path d="$path" $style/> ');
  }
  buffer.write('</svg>');
  return SvgPathsComponent(SvgPaths(buffer.toString()), hitboxes: hitboxes);
}

PathHitbox _perPathHitboxOf(String path, String style) {
  return _componentOf([(path, style)], hitboxes: SvgHitboxes.perPath).children
      .whereType<PathComponent>()
      .single
      .children
      .whereType<PathHitbox>()
      .single;
}

void main() {
  group('SvgPathsComponent', () {
    test('closes the open contours of filled paths for the hitbox', () {
      final hitbox = _perPathHitboxOf('M0 0L50 0L50 50', 'fill="#ff0000"');
      expect(hitbox.polygons.length, 1);
      expect(hitbox.containsLocalPoint(Vector2(40, 10)), isTrue);
    });

    test('closes the open contours of filled and stroked paths', () {
      final hitbox = _perPathHitboxOf(
        'M0 0L50 0L50 50',
        'fill="#ff0000" stroke="#000000" stroke-width="2"',
      );
      expect(hitbox.polygons.length, 1);
    });

    test('does not create polygons for open stroked paths', () {
      final hitbox = _perPathHitboxOf(
        'M0 0L50 0L50 50',
        'fill="none" stroke="#000000" stroke-width="2"',
      );
      expect(hitbox.polygons, isEmpty);
    });

    test('with perPath hitboxes, has a hitbox in each path component', () {
      final component = _componentOf(
        [
          ('M0 0L50 0L50 50Z', 'fill="#ff0000"'),
          ('M50 50L100 50L100 100Z', 'fill="#00ff00"'),
        ],
        hitboxes: SvgHitboxes.perPath,
      );
      final paths = component.children.whereType<PathComponent>().toList();
      expect(paths.length, 2);
      for (final path in paths) {
        expect(path.children.whereType<PathHitbox>().length, 1);
      }
      expect(component.children.whereType<SvgPathsHitbox>(), isEmpty);
    });

    test('with a single hitbox, has one hitbox for all the paths', () {
      final component = _componentOf([
        ('M0 0L50 0L50 50Z', 'fill="#ff0000"'),
        ('M50 50L100 50L100 100Z', 'fill="#00ff00"'),
      ]);
      // A hitbox is a PathComponent too.
      final paths = component.children
          .whereType<PathComponent>()
          .where((path) => path is! PathHitbox)
          .toList();
      expect(paths.length, 2);
      for (final path in paths) {
        expect(path.children.whereType<PathHitbox>(), isEmpty);
      }
      final hitbox = component.children.whereType<SvgPathsHitbox>().single;
      expect(hitbox.polygons.length, 2);
      // The hitbox is placed like the paths within the component.
      expect(hitbox.position.x, closeTo(0, 1e-6));
      expect(hitbox.position.y, closeTo(0, 1e-6));
      expect(hitbox.size.x, closeTo(100, 1e-6));
      expect(hitbox.size.y, closeTo(100, 1e-6));
    });
  });
}
