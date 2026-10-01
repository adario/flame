import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_svg/svg_paths.dart';
import 'package:flutter_test/flutter_test.dart';

String _svg(List<(String, String)> paths) {
  final buffer = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">',
  );
  for (final (index, (color, extra)) in paths.indexed) {
    final x = index * 10;
    buffer.write(
      '<path d="M$x 0L${x + 5} 0L${x + 5} 5Z" fill="$color" $extra/>',
    );
  }
  buffer.write('</svg>');
  return buffer.toString();
}

void main() {
  group('SvgPaths', () {
    test('without merge, keeps every path', () {
      final svg = SvgPaths(
        _svg([('#ff0000', ''), ('#ff0000', ''), ('#00ff00', '')]),
        merge: false,
      );
      expect(svg.length, 3);
    });

    test('merges consecutive paths with the same paint', () {
      final svg = SvgPaths(
        _svg([('#ff0000', ''), ('#ff0000', ''), ('#00ff00', '')]),
      );
      expect(svg.length, 2);
      expect(svg.paintAt(0)!.fill!.color.toARGB32(), 0xffff0000);
      expect(svg.paintAt(1)!.fill!.color.toARGB32(), 0xff00ff00);
    });

    test('does not merge paths separated by another paint', () {
      final svg = SvgPaths(
        _svg([('#ff0000', ''), ('#00ff00', ''), ('#ff0000', '')]),
      );
      expect(svg.length, 3);
      expect(svg.paintAt(0)!.fill!.color.toARGB32(), 0xffff0000);
      expect(svg.paintAt(1)!.fill!.color.toARGB32(), 0xff00ff00);
      expect(svg.paintAt(2)!.fill!.color.toARGB32(), 0xffff0000);
    });

    test('does not merge paths with both a fill and a stroke', () {
      final svg = SvgPaths(
        _svg([
          ('#ff0000', 'stroke="#000000" stroke-width="2"'),
          ('#ff0000', 'stroke="#000000" stroke-width="2"'),
        ]),
      );
      expect(svg.length, 2);
    });

    group('render', () {
      // A red square from (50, 50) to (55, 55), in a 100x100 SVG.
      final svg = SvgPaths(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"> '
        '<path d="M50 50L55 50L55 55L50 55Z" fill="#ff0000"/> </svg>',
      );

      Future<ByteData> render(WidgetTester tester, {Rect? area}) async {
        return (await tester.runAsync(() async {
          final recorder = PictureRecorder();
          svg.render(Canvas(recorder), Vector2.all(20), area: area);
          final image = await recorder.endRecording().toImage(20, 20);
          return image.toByteData();
        }))!;
      }

      int alphaAt(ByteData data, int x, int y) {
        return data.getUint8((y * 20 + x) * 4 + 3);
      }

      testWidgets('fits the whole SVG by default', (tester) async {
        final data = await render(tester);
        expect(alphaAt(data, 10, 10), 255); // The square at (10, 10).
        expect(alphaAt(data, 2, 2), 0);
      });

      testWidgets('fits the given area', (tester) async {
        final data = await render(
          tester,
          area: const Rect.fromLTWH(50, 50, 5, 5),
        );
        expect(alphaAt(data, 2, 2), 255);
        expect(alphaAt(data, 17, 17), 255);
      });
    });
  });
}
