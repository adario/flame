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
class SvgPaths {
  /// Create from an [svg] string, and perform an optional [merge]
  /// of consecutive SVG paths sharing the same paint.
  SvgPaths(String svg, {this.merge = true}) {
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
  /// or with a different fill type, are not merged.
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
    try {
      _instructions = parseWithoutOptimizers(svg);
    } on Exception catch (err) {
      // ignore: avoid_print
      print('!!! SVG error: $err');
      return;
    }

    final paints = <int, VectorPaint>{};
    final paths = <int, VectorPath>{};

    // The run of consecutive paths that are going to be merged, which are
    // added to the result as soon as the run ends. Merging only consecutive
    // paths keeps the painting order of the SVG file.
    final run = <VectorPath>[];
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
      final paint =
          paints[paintId] ??= _instructions.paints[paintId].toVectorPaint();
      final path =
          paths[pathId] ??= _instructions.paths[pathId].toVectorPath(
            paint,
            pathId: pathId,
            description: StringBuffer(),
          );

      // Paths with both a fill and a stroke are never merged, since the fill
      // and stroke of a merged path are painted after all of its paths, which
      // would change the painting order. The same goes for paths with a
      // different fill type, which a merged path can only have one of.
      final canMerge = merge && !(paint.isFilled && paint.isStroked);
      if (!canMerge ||
          paintId != runPaintId ||
          path.path.fillType != run.first.path.fillType) {
        endRun();
      }
      run.add(path);
      runPaint = paint;
      runPaintId = paintId;
      if (!canMerge) {
        endRun();
      }
    }
    endRun();
    assert(_paints.length == length, 'Paints/Paths length mismatch');
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
