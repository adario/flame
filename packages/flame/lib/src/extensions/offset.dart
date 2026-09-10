import 'dart:math';
import 'dart:ui';

import 'package:flame/src/extensions/vector2.dart';

export 'dart:ui' show Offset;

extension OffsetExtension on Offset {
  /// Creates an [Vector2] from the [Offset]
  Vector2 toVector2() => Vector2(dx, dy);

  /// Creates a [Size] from the [Offset]
  Size toSize() => Size(dx, dy);

  /// Creates a [Point] from the [Offset]
  Point toPoint() => Point(dx, dy);

  /// Creates a [Rect] starting in origin and going the [Offset]
  Rect toRect() => Rect.fromLTWH(0, 0, dx, dy);
}

extension FractEquals on Offset {
  /// Returns true if the two offsets are equal up to a certain number
  /// of decimal places; use zero for integral comparison.
  bool fractEquals(Offset other, {int digits = 3}) {
    assert(digits >= 0, 'The number of digits must be non-negative.');
    if (digits == 0) {
      return dx.toInt() == other.dx.toInt() && dy.toInt() == other.dy.toInt();
    }
    return dx.toStringAsFixed(digits) == other.dx.toStringAsFixed(digits) &&
        dy.toStringAsFixed(digits) == other.dy.toStringAsFixed(digits);
  }
}

extension OffsetListExtension on List<Offset> {
  /// Removes the last element if it matches the first one.
  /// If the [strict] parameter is `false`, equality checking is carried out
  /// via the above extension.
  bool removeDuplicateLast({bool strict = true, int digits = 3}) {
    if (length > 1 &&
        ((strict && first == last) ||
            (!strict && first.fractEquals(last, digits: digits)))) {
      removeLast();
      return true;
    }
    return false;
  }

  List<Vector2> get vertices =>
      map((o) => o.toVector2()).toList(growable: false);
}

extension VerticesList on List<List<Offset>> {
  /// Returns the given subcontour as a vertices list.
  List<Vector2> getVertices([int index = 0]) {
    assert(index >= 0 && index < length, 'Ivalid subcontour index $index');
    return this[index].vertices;
  }
}
