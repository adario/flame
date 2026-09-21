import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A paint object imported from a path in a SVG file. When present, the `fill`
/// component of the SVG style takes precedence over the `stroke` component.
@immutable
class VectorPaint {
  /// The fill component of the SVG style.
  final ui.Paint? fill;

  /// The stroke component of the SVG style.
  final ui.Paint? stroke;

  /// Create from the given [fill] and [stroke].
  const VectorPaint({this.fill, this.stroke});

  /// Create from the given [ui.Paint], which can only result in either
  /// [fill] or [stroke] being present (not both).
  VectorPaint.paint(ui.Paint paint)
    : fill = paint.style == .fill ? paint : null,
      stroke = paint.style == .stroke ? paint : null;

  /// Create from the given list of [paints]; if present, the first entry
  /// is assigned to the [fill], and the second (if present) to [stroke].
  VectorPaint.layers(List<ui.Paint> paints)
    : fill = paints.isNotEmpty ? paints.first : null,
      stroke = paints.length > 1 ? paints[1] : null;

  /// Return either the [fill] or [stroke] paint object.
  ui.Paint? get paint => fill ?? stroke;

  /// Return a list of [ui.Paint], with at most two elements, [fill] and
  /// [stroke].
  List<ui.Paint>? get paintLayers {
    final paints = <ui.Paint>[];
    if (fill != null) {
      paints.add(fill!);
    }
    if (stroke != null) {
      paints.add(stroke!);
    }
    return paints.isNotEmpty ? paints : null;
  }

  /// Whether the [fill] component is present.
  bool get isFilled => fill != null;

  /// Whether the [stroke] component is present.
  bool get isStroked => stroke != null;

  /// Whether both [fill] and [stroke] are present.
  bool get isFull => isStroked && isFilled;

  @override
  String toString() {
    var result = 'VectorPaint(';
    if (fill != null) {
      result += 'fill: $fill';
    }
    if (stroke != null) {
      if (fill != null) {
        result += ', ';
      }
      result += 'stroke: $stroke';
    }
    return '$result)';
  }

  @override
  int get hashCode => Object.hash(fill, stroke);

  @override
  bool operator ==(Object other) {
    if (other is VectorPaint) {
      return fill == other.fill && stroke == other.stroke;
    }
    return false;
  }
}
