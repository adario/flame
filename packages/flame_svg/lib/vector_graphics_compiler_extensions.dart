import 'dart:ui' as ui;

import 'package:flame_svg/vector_paint.dart';
import 'package:flame_svg/vector_path.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

/// BlendMode mapping from the vector graphics compiler.
extension BlendModeConverter on BlendMode {
  /// Converts a [BlendMode] to a [ui.BlendMode].
  ui.BlendMode toUiBlendMode() {
    switch (this) {
      case .clear:
        return .clear;
      case .color:
        return .color;
      case .colorBurn:
        return .colorBurn;
      case .colorDodge:
        return .colorDodge;
      case .darken:
        return .darken;
      case .difference:
        return .difference;
      case .dst:
        return .dst;
      case .dstATop:
        return .dstATop;
      case .dstIn:
        return .dstIn;
      case .dstOut:
        return .dstOut;
      case .dstOver:
        return .dstOver;
      case .exclusion:
        return .exclusion;
      case .hardLight:
        return .hardLight;
      case .hue:
        return .hue;
      case .lighten:
        return .lighten;
      case .luminosity:
        return .luminosity;
      case .modulate:
        return .modulate;
      case .multiply:
        return .multiply;
      case .overlay:
        return .overlay;
      case .plus:
        return .plus;
      case .saturation:
        return .saturation;
      case .screen:
        return .screen;
      case .softLight:
        return .softLight;
      case .src:
        return .src;
      case .srcATop:
        return .srcATop;
      case .srcIn:
        return .srcIn;
      case .srcOut:
        return .srcOut;
      case .srcOver:
        return .srcOver;
      case .xor:
        return .xor;
    }
  }
}

/// StrokeCap mapping from the vector graphics compiler.
extension StrokeCapConverter on StrokeCap {
  /// Converts a [StrokeCap] to a [ui.StrokeCap].
  ui.StrokeCap toUiStrokeCap() {
    switch (this) {
      case .butt:
        return .butt;
      case .round:
        return .round;
      case .square:
        return .square;
    }
  }
}

/// StrokeJoin mapping from the vector graphics compiler.
extension StrokeJoinConverter on StrokeJoin {
  /// Converts a [StrokeJoin] to a [ui.StrokeJoin].
  ui.StrokeJoin toUiStrokeJoin() {
    switch (this) {
      case .miter:
        return .miter;
      case .round:
        return .round;
      case .bevel:
        return .bevel;
    }
  }
}

/// Paint mapping from the vector graphics compiler.
extension PaintConverter on Paint {
  /// Converts a [Paint] to a [VectorPaint].
  VectorPaint toVectorPaint() {
    return VectorPaint(stroke: toStrokedUiPaint(), fill: toFilledUiPaint());
  }

  /// Possibly converts a stroked [Paint] to a [ui.Paint].
  ui.Paint? toStrokedUiPaint() {
    final s = stroke;
    if (s == null || s.width == null || s.width! <= 0) {
      return null;
    }
    final p = ui.Paint();
    p.style = .stroke;
    p.blendMode = blendMode.toUiBlendMode();
    p.strokeWidth = s.width ?? p.strokeWidth;
    p.strokeMiterLimit = s.miterLimit ?? p.strokeMiterLimit;
    p.color = ui.Color(s.color.value);
    final c = s.cap;
    if (c != null) {
      p.strokeCap = c.toUiStrokeCap();
    }
    final j = s.join;
    if (j != null) {
      p.strokeJoin = j.toUiStrokeJoin();
    }
    return p;
  }

  /// Possibly converts a filled [Paint] to a [ui.Paint].
  ui.Paint? toFilledUiPaint() {
    final f = fill;
    if (f == null) {
      return null;
    }
    final p = ui.Paint();
    p.style = .fill;
    p.blendMode = blendMode.toUiBlendMode();
    p.color = ui.Color(f.color.value);
    return p;
  }
}

/// Path mapping from the vector graphics compiler.
extension PathConverter on Path {
  /// Converts a [Path] to a [VectorPath], using the provided [paints] and
  /// optionally specifying a [pathId] and [description] for debugging purposes.
  VectorPath toVectorPath(
    VectorPaint paints, {
    int? pathId,
    StringBuffer? description,
  }) {
    return VectorPath(
      toUiPath(description),
      paints,
      pathId: pathId,
      description: description,
    );
  }

  /// Converts a [Path] to a [ui.Path], with the optional [description]
  /// for debugging purposes.
  ui.Path toUiPath([StringBuffer? description]) {
    description?.writeln('  path');
    final p = ui.Path();
    switch (fillType) {
      case .nonZero:
        p.fillType = .nonZero;
      case .evenOdd:
        p.fillType = .evenOdd;
    }
    for (final c in commands) {
      if (c is MoveToCommand) {
        p.moveTo(c.x, c.y);
        description?.writeln('    ..moveTo(${c.x}, ${c.y})');
      } else if (c is LineToCommand) {
        p.lineTo(c.x, c.y);
        description?.writeln('    ..lineTo(${c.x}, ${c.y})');
      } else if (c is CubicToCommand) {
        p.cubicTo(c.x1, c.y1, c.x2, c.y2, c.x3, c.y3);
        description?.writeln(
          '    ..cubicTo(${c.x1}, ${c.y1}, ${c.x2}, ${c.y2}, ${c.x3}, ${c.y3})',
        );
      } else if (c is CloseCommand) {
        p.close();
        description?.writeln('    ..close()');
      }
    }
    return p;
  }
}
