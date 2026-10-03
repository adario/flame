import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_svg/vector_graphics_compiler_extensions.dart';
import 'package:flame_svg/vector_paint.dart';
import 'package:flame_svg/vector_path.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

/// A container for SVG files, represented as a collection of [VectorPath]
/// and associated [VectorPaint] objects.
@immutable
class SvgPaths(String svg, {this.merge = true}) {
  /// Create from an [svg] string, and perform an optional [merge]
  /// of consecutive SVG paths sharing the same paint.
  ///
  /// Throws if the [svg] can not be parsed.
  this {
    _importSvg(svg);
  }

  /// Create an [SvgPaths] from a [fileName] in the `assets` folder,
  /// reachable via the [cache] (by default, [Flame.assets]), and
  /// optionally [merge] consecutive paths with identical paints.
  static Future<SvgPaths> fromFile(
    String fileName, {
    AssetsCache? cache,
    bool merge = true,
  }) async {
    final assets = cache ?? Flame.assets;
    final svg = await assets.readFile(fileName);
    assert(svg.isNotEmpty, 'SVG file not found: $fileName');
    return SvgPaths(svg, merge: merge);
  }

  /// Whether we merge consecutive paths with identical paints, which keeps
  /// the painting order of the SVG file. Paths with both a fill and a stroke,
  /// with a different fill type, or whose bounds, including their strokes,
  /// overlap those of the paths already merged, are not merged.
  final bool merge;

  /// The number of [VectorPath] objects in this container.
  int get length => _paths.length;

  /// The [VectorPath] at the given index, if any.
  VectorPath? pathAt(int index) {
    final validIndex = index >= 0 && index < length;
    assert(validIndex, 'Invalid vector path index $index');
    return validIndex ? _paths[index] : null;
  }

  /// The [VectorPaint] at the given index, if any.
  VectorPaint? paintAt(int index) {
    final validIndex = index >= 0 && index < _paints.length;
    assert(validIndex, 'Invalid paints index $index');
    return validIndex ? _paints[index] : null;
  }

  /// The original width reported by the [VectorInstructions].
  double get width => _instructions.width;

  /// The original width reported by the [VectorInstructions].
  double get height => _instructions.height;

  /// The original size reported by the [VectorInstructions].
  Size get size => Size(width, height);

  /// The original bounds for the whole SVG file, computed as the union
  /// of all the vector graphics compiler paths.
  ui.Rect get bounds => _computeBounds();

  /// Renders all paths on the [canvas], fitting the [area] of the SVG file
  /// into the dimensions in [size] while keeping the aspect ratio, and
  /// centering it. The [area] is the whole SVG file by default.
  ///
  /// An optional [overridePaint] is used instead of the [VectorPaint]s.
  void render(
    ui.Canvas canvas,
    Vector2 size, {
    ui.Paint? overridePaint,
    ui.Rect? area,
  }) {
    final source = area ?? ui.Rect.fromLTWH(0, 0, width, height);
    final scale = min(size.x / source.width, size.y / source.height);
    if (!scale.isFinite) {
      // There is nothing to fit, like in an empty SVG file.
      return;
    }
    canvas.save();
    canvas.translate(
      (size.x - source.width * scale) * 0.5 - source.left * scale,
      (size.y - source.height * scale) * 0.5 - source.top * scale,
    );
    canvas.scale(scale);

    final overrideVP = overridePaint != null
        ? VectorPaint.paint(overridePaint)
        : null;
    for (var i = 0; i < length; i++) {
      pathAt(i)?.render(canvas, overrideVP ?? paintAt(i));
    }

    canvas.restore();
  }

  /// Renders all paths on the [canvas] at the given [position] using the
  /// dimensions in [size], see [render].
  void renderPosition(
    ui.Canvas canvas,
    Vector2 position,
    Vector2 size, {
    ui.Rect? area,
  }) {
    canvas.renderAt(position, (c) => render(c, size, area: area));
  }

  // MARK: - Private methods

  void _importSvg(String svg) {
    _instructions = parseWithoutOptimizers(svg);

    final paints = <int, VectorPaint>{};
    final paths = <int, VectorPath>{};

    // The run of consecutive paths that are going to be merged, which are
    // added to the result as soon as the run ends. Merging only consecutive
    // paths keeps the painting order of the SVG file, and merging only paths
    // whose painted bounds do not overlap keeps their appearance: overlapping
    // contours of a merged path could cancel each other out, depending on
    // their direction and on the fill type, and overlapping translucent paints
    // would not add up.
    final run = <VectorPath>[];
    final runBounds = <ui.Rect>[];
    VectorPaint? runPaint;
    int? runPaintId;

    void endRun() {
      if (run.isEmpty) {
        return;
      }
      if (run.length == 1) {
        _paths.add(run.first);
      } else {
        final merged = ui.Path()..fillType = run.first.path.fillType;
        for (final path in run) {
          merged.addPath(path.path, .zero);
        }
        _paths.add(
          VectorPath(
            merged,
            runPaint!,
            pathId: _paths.length,
            description: StringBuffer(),
          ),
        );
      }
      _paints.add(runPaint!);
      run.clear();
      runBounds.clear();
      runPaint = null;
      runPaintId = null;
    }

    // Walk all vector instructions, considering only path commands.
    for (final c in _instructions.commands) {
      if (c.type != .path) {
        // Other commands, like clipping, separate the paths around them.
        debugPrint('SVG skipping draw command = $c');
        endRun();
        continue;
      }

      final paintId = c.paintId;
      final pathId = c.objectId;
      assert(paintId != null && pathId != null, 'Invalid path or paint ID');
      if (paintId == null || pathId == null) {
        endRun();
        continue;
      }

      // Convert the paint and the path.
      final paint = paints[paintId] ??= _instructions.paints[paintId]
          .toVectorPaint();
      final path = paths[pathId] ??= _instructions.paths[pathId].toVectorPath(
        paint,
        pathId: pathId,
        description: StringBuffer(),
      );

      // Paths with both a fill and a stroke are never merged, since the fill
      // and stroke of a merged path are painted after all of its paths, which
      // would change the painting order. The same goes for paths with a
      // different fill type, which a merged path can only have one of.
      final canMerge = merge && !(paint.isFilled && paint.isStroked);
      final bounds = _paintedBounds(path.path.getBounds(), paint);
      if (!canMerge ||
          paintId != runPaintId ||
          path.path.fillType != run.first.path.fillType ||
          runBounds.any(bounds.overlaps)) {
        endRun();
      }
      run.add(path);
      runBounds.add(bounds);
      runPaint = paint;
      runPaintId = paintId;
      if (!canMerge) {
        endRun();
      }
    }
    endRun();
    assert(_paints.length == length, 'Paints/Paths length mismatch');
  }

  /// The [bounds] of a path, grown to include its stroke, if any. The stroke
  /// can reach up to the miter limit, which is 4 by default, times half of its
  /// width, so we use twice its width to be on the safe side.
  static ui.Rect _paintedBounds(ui.Rect bounds, VectorPaint paint) {
    final stroke = paint.stroke;
    return stroke == null ? bounds : bounds.inflate(stroke.strokeWidth * 2);
  }

  ui.Rect _computeBounds() {
    var bounds = ui.Rect.zero;
    for (final path in _instructions.paths) {
      final b = path.bounds().toUiRect();
      if (bounds == .zero) {
        bounds = b;
      } else {
        bounds = bounds.expandToInclude(b);
      }
    }
    return bounds;
  }

  late final VectorInstructions _instructions;
  late final List<VectorPath> _paths = [];
  late final List<VectorPaint> _paints = [];
}
