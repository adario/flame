import 'dart:math' as math;
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
/// and associated [VectorPaint] objects
class SvgPaths {
  /// Create from an [svg] string.
  SvgPaths(String svg, {this.merge = true}) {
    _importSvg(svg);
  }

  /// Create an [SvgPaths] from a [fileName] in the `assets` folder,
  /// reachable via the [cache] (by default, [Flame.assets]), and
  /// optionally merge paths with identical paints.
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

  /// Whether we merge paths with identical paints.
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
  VectorPaint? paintsAt(int index) {
    final validIndex = index >= 0 && index < _paints.length;
    assert(validIndex, 'Invalid paints index $index');
    return validIndex ? _paints[index] : null;
  }

  /// The original width reported by the [VectorInstructions].
  double get width => _instructions.width;

  /// The original width reported by the [VectorInstructions].
  double get height => _instructions.height;

  /// The original bounds for all paths.
  ui.Rect get bounds => _bounds ??= _computeBounds();

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

  /// Renders the svg on the [canvas] on the given [position] using the
  /// dimensions in [size].
  void renderPosition(ui.Canvas canvas, Vector2 position, Vector2 size) {
    canvas.renderAt(position, (c) => render(c, size));
  }

  // MARK: - Private methods

  void _render(ui.Canvas canvas, ui.Paint? overridePaint) {
    assert(_paints.length == length, 'Paints length mismatch');
    final overrideVP = overridePaint != null
        ? VectorPaint.paint(overridePaint)
        : null;
    for (var i = 0; i < length; i++) {
      _paths[i].render(canvas, overrideVP ?? _paints[i]);
    }
  }

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
    final pathPaints = <int, List<VectorPath>>{};

    // Walk all vector instructions, considering only path commands.
    for (final c in _instructions.commands) {
      if (c.type != .path) {
        debugPrint('SVG skipping draw command = $c');
        continue;
      }

      // Convert the paint for the current path.
      final paintId = c.paintId;
      VectorPaint? paint;
      if (paintId != null) {
        paint =
            paints[paintId] ?? _instructions.paints[paintId].toVectorPaint();
        paints[paintId] = paint;
        _paints.add(paint);
      }

      // Convert the current path.
      final pathId = c.objectId;
      if (pathId != null) {
        final path =
            paths[pathId] ??
            _instructions.paths[pathId].toVectorPath(
              paint!,
              pathId: pathId,
              description: StringBuffer(),
            );
        paths[pathId] = path;
        _paths.add(path);

        // If a merge is requested, Keep track of all paths using
        // the current paint.
        if (merge) {
          assert(paintId != null, 'Path $pathId has no valid paint');
          if (paintId != null) {
            if (pathPaints[paintId] == null) {
              pathPaints[paintId] = [path];
            } else {
              pathPaints[paintId]!.add(path);
            }
          }
        }
      }
    }
    assert(_paints.length == length, 'Paints/Paths length mismatch');

    if (pathPaints.isNotEmpty && paints.length < paths.length) {
      // If requested and we have fewer paints than paths, merge all those
      // sharing the same paint.
      _merge(paints, pathPaints);
    }
  }

  void _merge(
    Map<int, VectorPaint> paints,
    Map<int, List<VectorPath>> pathPaints,
  ) {
    _paths.clear();
    _paints.clear();

    for (final entry in pathPaints.entries) {
      final index = entry.key;
      final paths = entry.value;
      final paint = paints[index]!;
      final merged = ui.Path();
      for (final path in paths) {
        merged.addPath(path.path, .zero);
      }
      _paths.add(
        VectorPath(
          merged,
          paint,
          pathId: paths.length,
          description: StringBuffer(),
        ),
      );
      _paints.add(paint);
    }
  }

  ui.Rect _computeBounds() {
    var bounds = ui.Rect.zero;
    for (final path in _instructions.paths) {
      final x = path.bounds();
      final t = ui.Rect.fromLTRB(x.left, x.top, x.right, x.bottom);
      bounds = bounds.expandToInclude(t);
    }
    return bounds;
  }

  ui.Rect? _bounds;
  late final VectorInstructions _instructions;
  late final List<VectorPath> _paths = [];
  late final List<VectorPaint> _paints = [];
}
