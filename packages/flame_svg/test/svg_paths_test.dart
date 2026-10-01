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

    group('merge with overlapping paths', () {
      String svgOf(List<String> paths, [String style = '']) {
        final elements = [
          for (final d in paths) '<path d="$d" fill="#ff0000" $style/> ',
        ];
        return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"> '
            '${elements.join()}</svg>';
      }

      const a = 'M0 0L50 0L50 50L0 50Z';
      const overlapsA = 'M25 25L75 25L75 75L25 75Z';
      const farFromA = 'M60 60L90 60L90 90L60 90Z';
      const besideA = 'M50 0L90 0L90 50L50 50Z';

      test('merges paths that do not overlap', () {
        expect(SvgPaths(svgOf([a, farFromA])).length, 1);
      });

      test('merges paths that only touch', () {
        expect(SvgPaths(svgOf([a, besideA])).length, 1);
      });

      test('does not merge paths that overlap', () {
        expect(SvgPaths(svgOf([a, overlapsA])).length, 2);
      });

      test('merges the paths after an overlap that do not overlap', () {
        // The second path overlaps the first one, but not the third one.
        const farFromBoth = 'M80 80L95 80L95 95L80 95Z';
        expect(SvgPaths(svgOf([a, overlapsA, farFromBoth])).length, 2);
      });

      test('does not merge strokes that only reach each other', () {
        // The lines are 5 units apart, and their strokes are 4 units wide.
        const lines = ['M10 10L90 10', 'M10 15L90 15'];
        const style = 'fill="none" stroke="#000000" stroke-width="4"';
        expect(SvgPaths(svgOf(lines, style)).length, 2);
        expect(SvgPaths(svgOf(lines, style), merge: false).length, 2);
      });

      testWidgets('keeps the overlap of even-odd paths filled', (tester) async {
        final svg = SvgPaths(
          svgOf([a, overlapsA], 'fill-rule="evenodd"'),
        );
        final alpha = (await tester.runAsync(() async {
          final recorder = PictureRecorder();
          svg.render(Canvas(recorder), Vector2.all(100));
          final image = await recorder.endRecording().toImage(100, 100);
          final data = (await image.toByteData())!;
          return data.getUint8((35 * 100 + 35) * 4 + 3);
        }))!;
        expect(alpha, 255);
      });
    });

    group('with an SVG that can not be used', () {
      test('throws if it can not be parsed', () {
        expect(() => SvgPaths('garbage'), throwsA(anything));
        expect(() => SvgPaths(''), throwsA(anything));
      });

      testWidgets('renders nothing if it is empty', (tester) async {
        final svg = SvgPaths(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"/>',
        );
        expect(svg.length, 0);
        final recorder = PictureRecorder();
        expect(
          () =>
              svg.render(Canvas(recorder), Vector2.all(100), area: svg.bounds),
          returnsNormally,
        );
      });
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
