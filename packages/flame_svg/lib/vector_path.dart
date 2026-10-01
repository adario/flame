import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flame_svg/vector_paint.dart';
import 'package:flutter/foundation.dart';

/// A path originating from the vector graphics compiler, and represented by
/// a standard [ui.Path] and a [VectorPaint] object.
@immutable
class VectorPath {
  /// Create from the given [path] and [paint].
  VectorPath(
    this.path,
    this.paint, {
    this.pathId,
    this.description,
  }) {
    if (paint.isFilled) {
      _processFilled();
    } else if (paint.isStroked) {
      _processStroked();
    } else {
      assert(
        paint.isFilled || paint.isStroked,
        'VectorPath must have at least a stroke or a fill.',
      );
      throw ArgumentError(
        'VectorPath must have at least a stroke or a fill.',
      );
    }
  }

  void _processStroked() {
    // Stroked paths are simpler: we just use the original path as the stroke.
    _strokePath = path;
    _fillPath = null;
    description?.writeln('VectorPath $pathId: stroked path');
  }

  void _processFilled() {
    // Analyze filled path to determine which open/closed contours it contains.
    final contours = path.contours;
    final totalLength = contours.contoursLength;
    description?.writeln(
      'VectorPath $pathId: #${contours.length} contours, length: $totalLength',
    );
    for (final metric in contours) {
      // Extract the contour path, and add it to the open or closed list.
      final p = metric.extractPath(0, metric.length);
      if (metric.isClosed) {
        _closed.add(p);
      } else {
        _open.add(p);
      }
    }

    // Now we process the open/closed contours, creating stroked/filled paths:
    // sometimes the paint style we receive from the vector graphics compiler
    // is not consistent with the actual path.
    var stroke = _open.isNotEmpty ? _addOpen() : null;
    var fill = _closed.isNotEmpty ? _addClosed() : null;
    if (_closed.isNotEmpty) {
      // If we have both open and closed contours with corresponding
      // single contours, merge them accordingly.
      if (stroke != null) {
        if (_open.length == 1) {
          fill!.addPath(stroke, .zero);
        } else if (_closed.length == 1) {
          stroke.addPath(fill!, .zero);
        }
      }
    } else {
      // No closed contours: if we have open contours and the paints
      // are not stroked, we keep only the fill path.
      if (!paint.isStroked && _open.isNotEmpty) {
        fill = stroke;
        stroke = null;
      }
    }
    _fillPath = fill;
    _strokePath = stroke;
    assert(
      _fillPath != null || _strokePath != null,
      'VectorPath must have at least a stroke or a fill.',
    );
  }

  // Create a path that merges all open contours.
  ui.Path _addOpen() {
    final result = ui.Path();
    result.fillType = path.fillType;
    for (final p in _open) {
      result.addPath(p, ui.Offset.zero);
    }
    return result;
  }

  // Create a path that merges all closed contours.
  ui.Path _addClosed() {
    final result = ui.Path();
    result.fillType = path.fillType;
    for (final p in _closed) {
      result.addPath(p, ui.Offset.zero);
    }
    return result;
  }

  /// Renders the path on the [canvas] with an optional [overridePaint], used
  /// instead of the default [paint].
  ///
  /// The fill is drawn from the original [path], so that its open contours
  /// are closed implicitly, like in the SVG file, and so is the stroke, so
  /// that closed contours are stroked as well.
  void render(ui.Canvas canvas, [VectorPaint? overridePaint]) {
    final paint = overridePaint ?? this.paint;
    if (paint.fill != null) {
      canvas.drawPath(path, paint.fill!);
    }
    if (paint.stroke != null) {
      canvas.drawPath(path, paint.stroke!);
    }
  }

  /// The default paint.
  final VectorPaint paint;

  /// The original path.
  final ui.Path path;

  /// The stroked path (if any).
  ui.Path? get strokePath => _strokePath;

  /// The filled path (if any).
  ui.Path? get fillPath => _fillPath;

  /// The original path ID.
  final int? pathId;

  late final ui.Path? _strokePath;
  late final ui.Path? _fillPath;

  final _open = <ui.Path>[];
  final _closed = <ui.Path>[];

  /// Optional description for debugging purposes.
  final StringBuffer? description;

  @override
  String toString() {
    var desc =
        'paint: $paint, open: ${_open.length}, closed: ${_closed.length}';
    desc = 'VectorPath($desc)';
    if (description != null) {
      desc += '\n${description!}';
    }
    return desc;
  }

  @override
  int get hashCode => Object.hash(paint, _open.length, _closed.length);

  @override
  bool operator ==(Object other) {
    if (other is VectorPath) {
      return paint == other.paint &&
          _open.length == other._open.length &&
          _closed.length == other._closed.length;
    }
    return false;
  }
}
