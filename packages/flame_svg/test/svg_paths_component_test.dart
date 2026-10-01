import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter_test/flutter_test.dart';

SvgPathsComponent _componentOf(
  List<(String, String)> paths, {
  SvgHitboxes hitboxes = SvgHitboxes.single,
  Vector2? size,
  double sampling = 1.0,
  bool renderHitboxes = false,
}) {
  final buffer = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"> ',
  );
  for (final (path, style) in paths) {
    buffer.write('<path d="$path" $style/> ');
  }
  buffer.write('</svg>');
  return SvgPathsComponent(
    SvgPaths(buffer.toString()),
    hitboxes: hitboxes,
    size: size,
    sampling: sampling,
    renderHitboxes: renderHitboxes,
  );
}

int _vertices(SvgPathsComponent component) {
  final hitbox = component.children.whereType<SvgPathsHitbox>().single;
  return hitbox.polygons.fold(0, (sum, polygon) => sum + polygon.length);
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
    group('assetPath', () {
      test('is in assets/svgs by default', () {
        expect(SvgPathsComponent.assetPath('ship'), 'assets/svgs/ship.svg');
      });

      test('adds the missing slash of the folder', () {
        expect(
          SvgPathsComponent.assetPath('ship', 'assets/other'),
          'assets/other/ship.svg',
        );
      });

      test('keeps the slash of the folder', () {
        expect(
          SvgPathsComponent.assetPath('ship', 'assets/other/'),
          'assets/other/ship.svg',
        );
      });
    });

    test('has no children for an empty SVG', () {
      final svg = SvgPaths(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"/>',
      );
      for (final hitboxes in SvgHitboxes.values) {
        final component = SvgPathsComponent(
          svg,
          hitboxes: hitboxes,
          size: Vector2.all(100),
        );
        expect(component.children, isEmpty, reason: hitboxes.name);
      }
    });

    group('hitbox paints', () {
      const paths = [
        ('M0 0L50 0L50 50Z', 'fill="#ff0000"'),
        ('M50 50L100 50L100 100Z', 'fill="#00ff00"'),
      ];

      test('are not shared between per-path hitboxes', () {
        final component = _componentOf(
          paths,
          hitboxes: SvgHitboxes.perPath,
          renderHitboxes: true,
        );
        final hitboxes = component.children
            .whereType<PathComponent>()
            .map((path) => path.children.whereType<PathHitbox>().single)
            .toList();
        expect(hitboxes.length, 2);
        expect(identical(hitboxes[0].paint, hitboxes[1].paint), isFalse);
      });

      test('are not shared between single hitboxes', () {
        final first = _componentOf(paths, renderHitboxes: true);
        final second = _componentOf(paths, renderHitboxes: true);
        expect(
          identical(
            first.children.whereType<SvgPathsHitbox>().single.paint,
            second.children.whereType<SvgPathsHitbox>().single.paint,
          ),
          isFalse,
        );
      });
    });

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

    group('polygon sampling', () {
      // A circle in a small SVG, so that it is scaled up a lot.
      const circle = [
        (
          'M16 0A16 16 0 1 1 16 32A16 16 0 1 1 16 0Z',
          'fill="#ff0000"',
        ),
      ];

      test('is in the units of the component, not of the SVG', () {
        final small = _componentOf(circle, size: Vector2.all(32));
        final large = _componentOf(circle, size: Vector2.all(320));
        // The same shape needs more vertices to be followed as closely when
        // it is ten times larger.
        expect(_vertices(large), greaterThan(_vertices(small)));
      });

      test('can be coarser', () {
        final fine = _componentOf(circle, size: Vector2.all(320));
        final coarse = _componentOf(
          circle,
          size: Vector2.all(320),
          sampling: 40,
        );
        expect(_vertices(coarse), lessThan(_vertices(fine)));
      });
    });

    test('with a single hitbox, has one hitbox for all the paths', () {
      final component = _componentOf([
        ('M0 0L50 0L50 50Z', 'fill="#ff0000"'),
        ('M50 50L100 50L100 100Z', 'fill="#00ff00"'),
      ]);
      // The paths are rendered by the component, so there are no path
      // components, and the hitbox is the only child.
      expect(component.children.length, 1);
      final hitbox = component.children.whereType<SvgPathsHitbox>().single;
      expect(hitbox.polygons.length, 2);
      // The hitbox is placed like the paths within the component.
      expect(hitbox.position.x, closeTo(0, 1e-6));
      expect(hitbox.position.y, closeTo(0, 1e-6));
      expect(hitbox.size.x, closeTo(100, 1e-6));
      expect(hitbox.size.y, closeTo(100, 1e-6));
    });

    group('rendering', () {
      const paths = [
        // An open contour, which a fill closes.
        ('M5 5L40 5L40 40', 'fill="#ff0000"'),
        // A ring: the hole is not filled.
        (
          'M55 55L95 55L95 95L55 95ZM65 65L65 85L85 85L85 65Z',
          'fill="#00ff00" fill-rule="evenodd"',
        ),
        // A closed contour with a fill and a stroke.
        (
          'M5 55L40 55L40 90L5 90Z',
          'fill="#0000ff" stroke="#ffffff" stroke-width="6"',
        ),
        // An open contour with a stroke only.
        ('M50 5L95 5', 'fill="none" stroke="#ffff00" stroke-width="4"'),
      ];

      Future<ByteData> render(WidgetTester tester, SvgHitboxes hitboxes) async {
        return (await tester.runAsync(() async {
          final component = _componentOf(
            paths,
            hitboxes: hitboxes,
            size: Vector2.all(100),
          );
          final recorder = ui.PictureRecorder();
          component.renderTree(ui.Canvas(recorder));
          final image = await recorder.endRecording().toImage(100, 100);
          return image.toByteData();
        }))!;
      }

      int alphaAt(ByteData data, int x, int y) {
        return data.getUint8((y * 100 + x) * 4 + 3);
      }

      testWidgets('draws open filled contours and skips holes', (tester) async {
        final data = await render(tester, SvgHitboxes.single);
        // Inside of the closed open triangle, and of the ring but not its hole.
        expect(alphaAt(data, 30, 15), 255);
        expect(alphaAt(data, 60, 90), 255);
        expect(alphaAt(data, 75, 75), 0);
      });

      testWidgets('is the same with a single hitbox and per path', (
        tester,
      ) async {
        final single = await render(tester, SvgHitboxes.single);
        final perPath = await render(tester, SvgHitboxes.perPath);
        var different = 0;
        for (var i = 0; i < single.lengthInBytes; i++) {
          if ((single.getUint8(i) - perPath.getUint8(i)).abs() > 64) {
            different++;
          }
        }
        // Only a few pixels on the edges may differ.
        expect(different, lessThan(100 * 100 * 4 * 0.01));
      });
    });
  });
}
