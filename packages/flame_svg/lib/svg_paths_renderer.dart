import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flame_svg/svg_paths.dart';
import 'package:flame_svg/vector_paint.dart';

/// The [SvgPathsRenderer] mixin supports rendering an [SvgPaths] to a [Canvas],
/// with an optional [VectorPaint].
mixin SvgPathsRenderer on SvgPaths {
  /// Renders all paths on the [canvas] using the dimensions in [size]
  /// with an optional [overridePaint] used instead of the [VectorPaint]s.
  void render(ui.Canvas canvas, Vector2 size, {ui.Paint? overridePaint}) {
    final scale = math.min(size.x / width, size.y / height);
    canvas.save();
    canvas.translate(
      (size.x - width * scale) * 0.5,
      (size.y - height * scale) * 0.5,
    );
    canvas.scale(scale);

    _render(canvas, overridePaint);

    canvas.restore();
  }

  /// Renders all paths on the [canvas] at the given [position] using the
  /// dimensions in [size].
  void renderPosition(ui.Canvas canvas, Vector2 position, Vector2 size) {
    canvas.renderAt(position, (c) => render(c, size));
  }

  // MARK: - Private methods

  void _render(ui.Canvas canvas, ui.Paint? overridePaint) {
    final overrideVP = overridePaint != null
        ? VectorPaint.paint(overridePaint)
        : null;
    for (var i = 0; i < length; i++) {
      pathAt(i)?.render(canvas, overrideVP ?? paintAt(i));
    }
  }
}
