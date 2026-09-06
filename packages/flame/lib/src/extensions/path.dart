import 'dart:typed_data' show Float32List;
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart' show Transform2D, Vector2;
import 'package:flame/src/cache/matrix_pool.dart' show pathTransform;
import 'package:flame/src/extensions/offset.dart' show FractEquals;

export 'dart:ui' show Path;

extension PathExtension on Path {
  Path transform32(Float32List matrix4) {
    return pathTransform(this, matrix4);
  }

  Path resizeTo(Size size, {bool keepRatio = false}) {
    assert(
      size.width > 0 && size.height > 0,
      'Resizing with invalid size: $size',
    );
    final box = getBounds();
    final scale = Vector2(size.width / box.width, size.height / box.height);
    if (keepRatio) {
      if (box.height > box.width) {
        scale.setValues(scale.y, scale.y);
      } else {
        scale.setValues(scale.x, scale.x);
      }
    }
    final t = Transform2D()..scale = scale;
    return transform32(t.transformMatrix.storage);
  }

  Path get toOrigin {
    final box = getBounds();
    final origin = box.topLeft;
    if (origin != .zero) {
      return shift(-origin);
    }
    return this;
  }

  Path get centered {
    final box = getBounds();
    final center = box.center;
    if (center != .zero) {
      return toOrigin.shift(-(box.size.toOffset() * 0.5));
    }
    return this;
  }
}

typedef PathMetricList = List<PathMetric>;
typedef OffsetList = List<Offset>;

extension PathContours on Path {
  /// Return a list of [PathMetric] objects, corresponding to the contours
  /// in this path.
  PathMetricList get contours {
    return computeMetrics().toList(growable: false);
  }

  /// Walk the contours of a [Path] and return them as a list of [Offset] lists.
  /// Each entry in the list corresponds to a given sub-contour.
  /// The optional [pathLength] represents a pre-computed path length
  /// for paths that contain a single contour.
  /// The [granularity] parameter controls the amplitude of the sampling step.
  List<OffsetList> walkContours([
    double? pathLength,
    double granularity = 1.0,
  ]) {
    final contours = this.contours;
    final totalLength = contours.contoursLength;
    final allPoints = <OffsetList>[];
    for (final metric in contours) {
      allPoints.add(metric.walkContour(totalLength, pathLength, granularity));
    }
    return allPoints;
  }
}

extension Contour on PathMetric {
  static const _threshold = 0.1;

  /// Walk a single contour of a [Path] and return it as an [Offset] list.
  /// The optional [pathLength] represents a pre-computed path length,
  /// used when this contour length matches the [totalLength] of the path.
  /// The [granularity] parameter controls the amplitude of the sampling step.
  /// (This is obviously not clear enough...)
  OffsetList walkContour(
    double totalLength, [
    double? pathLength,
    double granularity = 1.0,
  ]) {
    final amount = length / totalLength;
    final pathAmount = length / (pathLength ?? totalLength);
    var step = amount != 1 ? amount : pathAmount;
    if (step < _threshold) {
      step *= 1.0 / _threshold;
    }
    if (granularity > 0) {
      step *= granularity;
    }
    Offset? lastVector;
    final points = <Offset>[];

    void add(Tangent? tangent, {bool force = false}) {
      if (tangent == null) {
        return;
      }
      var differs = false;
      if (lastVector != null) {
        differs = !tangent.vector.fractEquals(lastVector!, digits: 1);
      }
      lastVector = tangent.vector;
      if (differs || force) {
        points.add(tangent.position);
      }
    }

    for (double distance = 0; distance < length; distance += step) {
      final tangent = getTangentForOffset(distance);
      assert(tangent != null, 'Tangent is null at distance $distance');
      add(tangent, force: distance == 0);
    }
    final tangent = getTangentForOffset(length);
    add(tangent, force: true);
    return points;
  }
}

extension Contours on PathMetrics {
  /// Return all the [PathMetric]s from a [Path]'s pre-computed metrics.
  PathMetricList get contours {
    return toList(growable: false);
  }

  /// Return the length of all contours in a [Path]'s pre-computed metrics.
  double get contoursLength {
    return contours.contoursLength;
  }
}

extension ContoursLength on PathMetricList {
  /// Compute the cumulative length of a [List] of [PathMetric] objects,
  /// provided by the [PathContours] extension.
  double get contoursLength {
    return fold(0.0, (sum, metric) => sum + metric.length);
  }
}
