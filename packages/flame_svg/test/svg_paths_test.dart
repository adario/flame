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
  });
}
