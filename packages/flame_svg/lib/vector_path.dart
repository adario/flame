// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
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
    _prepare();
  }

  void _prepare() {
    if (paint.isFilled) {
      _analyze();
    } else if (paint.isStroked) {
      _strokePath = path;
    } else {
      assert(
        paint.isFilled || paint.isStroked,
        'VectorPath must have at least a stroke or a fill.',
      );
    }
  }

  void _analyze() {
    // Analyze the path to determine which open/closed contours it contains.
    final contours = path.contours;
    final totalLength = contours.contoursLength;
    debugPrint(
      'VectorPath $pathId: #${contours.length} contours, length: $totalLength',
    );
    for (final metric in contours) {
      final p = metric.extractPath(0, metric.length);
      if (metric.isClosed) {
        _closed.add(p);
      } else {
        _open.add(p);
      }
    }

    ui.Path? stroke;
    ui.Path? fill;
    if (_open.isNotEmpty) {
      // Create a path for the open contours.
      stroke = _addOpen();
    }

    if (_closed.isNotEmpty) {
      // Create a path for the closed contours.
      fill = _addClosed();

      // If we have both open and closed contours with corresponding
      // single contours, merge them accordingly.
      if (stroke != null) {
        if (_open.length == 1) {
          fill.addPath(stroke, .zero);
        } else if (_closed.length == 1) {
          stroke.addPath(fill, .zero);
        }
      }
    } else {
      // No closed contours, but we have open contours. If the paints
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

  ui.Path _addOpen() {
    final result = ui.Path();
    result.fillType = path.fillType;
    for (final p in _open) {
      result.addPath(p, ui.Offset.zero);
    }
    return result;
  }

  ui.Path _addClosed() {
    final result = ui.Path();
    result.fillType = path.fillType;
    for (final p in _closed) {
      result.addPath(p, ui.Offset.zero);
    }
    return result;
  }

  /// Render both fill and stroke paths on the given [canvas],
  /// with an optional [overridePaint].
  void render(ui.Canvas canvas, VectorPaint? overridePaint) {
    final paint = overridePaint ?? this.paint;
    if (_fillPath != null && paint.fill != null) {
      canvas.drawPath(_fillPath, paint.fill!);
    }
    if (_strokePath != null && paint.stroke != null) {
      canvas.drawPath(_strokePath, paint.stroke!);
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
