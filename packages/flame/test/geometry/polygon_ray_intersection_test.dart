// ignore_for_file: lines_longer_than_80_chars, avoid_print

import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flame/geometry.dart';
import 'package:test/test.dart';

const _testWidth = 1024.0;
const _testHeight = 768.0;

int _verbose = 0;

Path roundRectPath(Size size) {
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.shortestSide * 0.25),
    ),
  );
}

Path flamePath() {
  return Path()
    ..moveTo(62.0, 42.8)
    ..cubicTo(62.0, 58.9, 49.0, 65.0, 33.0, 65.0)
    ..cubicTo(17.0, 65.0, 4.0, 58.9, 4.0, 42.8)
    ..cubicTo(4.0, 38.6, 4.9, 35.9, 6.5, 32.2)
    ..cubicTo(7.6, 29.8, 10.1, 40.7, 11.9, 38.8)
    ..cubicTo(16.2, 34.1, 7.2, 23.3, 23.8, 15.2)
    ..cubicTo(20.8, 23.5, 23.2, 26.8, 26.4, 26.8)
    ..cubicTo(33.4, 26.8, 33.5, 16.3, 32.7, 3.0)
    ..cubicTo(54.1, 19.6, 42.3, 26.0, 44.7, 28.1)
    ..cubicTo(56.6, 29.4, 48.7, 3.1, 59.3, 28.3)
    ..cubicTo(61.3, 32.8, 62.0, 37.5, 62.0, 42.8)
    ..close();
}

List<Vector2> pathVertices(Path path) {
  final contours = path.centered.walkContours(null, 2);
  assert(contours.isNotEmpty, 'Empty path contours');
  final vertices = contours.first.map((offset) => offset.toVector2()).toList();
  if (vertices.length > 1 && vertices.first == vertices.last) {
    vertices.removeLast();
  }
  return vertices;
}

class _RayCase {
  _RayCase(this.ray, {required this.expectsHit});

  final Ray2 ray;
  final bool expectsHit;
}

List<_RayCase> _randomRayCases(
  PolygonHitbox polygon,
  int count,
  Random random, {
  Vector2? safePoint,
}) {
  final cases = <_RayCase>[];
  final halfCount = count ~/ 2;

  Vector2 randomInsidePoint() {
    Vector2 point;
    do {
      point = Vector2(
        random.nextDouble() * polygon.size.x,
        random.nextDouble() * polygon.size.y,
      );
    } while (!polygon.containsLocalPoint(point));
    return safePoint == null ? point : safePoint + (point - safePoint) * 0.5;
  }

  for (var index = 0; index < halfCount; index++) {
    cases.add(
      _RayCase(
        Ray2(
          origin: randomInsidePoint(),
          direction: Vector2(
            random.nextDouble() * 2 - 1,
            random.nextDouble() * 2 - 1,
          ).normalized(),
        ),
        expectsHit: true,
      ),
    );
  }

  for (var index = 0; index < count - halfCount; index++) {
    final target = randomInsidePoint();
    final origin = Vector2(
      polygon.size.x + random.nextDouble() * _testWidth,
      polygon.size.y + random.nextDouble() * _testHeight,
    );
    final pointsTowardPolygon = index.isEven;
    cases.add(
      _RayCase(
        Ray2(
          origin: origin,
          direction: (pointsTowardPolygon ? target - origin : origin - target)
              .normalized(),
        ),
        expectsHit: pointsTowardPolygon,
      ),
    );
  }

  return cases;
}

typedef BatchResult = (int, int);

void main() {
  test('does not classify an outside vertex hit as inside', () {
    final hitbox = PolygonHitbox([
      Vector2(0, 0),
      Vector2(10, 0),
      Vector2(10, 10),
      Vector2(0, 10),
    ]);

    final result = hitbox.rayIntersection(
      Ray2(origin: Vector2(-1, -1), direction: Vector2(1, 1).normalized()),
    );

    expect(result, isNotNull);
    expect(result!.isInsideHitbox, isTrue);

    final correctedResult = hitbox.rayIntersection(
      Ray2(origin: Vector2(-1, -1), direction: Vector2(1, 1).normalized()),
      useContainment: true,
    );

    expect(correctedResult, isNotNull);
    expect(correctedResult!.isInsideHitbox, isFalse);
  });

  test('classifies a concave polygon with multiple crossings correctly', () {
    final hitbox = PolygonHitbox([
      Vector2(0, 0),
      Vector2(4, 0),
      Vector2(4, 4),
      Vector2(3, 4),
      Vector2(3, 1),
      Vector2(1, 1),
      Vector2(1, 4),
      Vector2(0, 4),
    ]);

    final result = hitbox.rayIntersection(
      Ray2(origin: Vector2(0.5, 2), direction: Vector2(1, 0)),
    );

    expect(result, isNotNull);
    expect(result!.isInsideHitbox, isFalse);

    final correctedResult = hitbox.rayIntersection(
      Ray2(origin: Vector2(0.5, 2), direction: Vector2(1, 0)),
      useContainment: true,
    );

    expect(correctedResult, isNotNull);
    expect(correctedResult!.isInsideHitbox, isTrue);
  });

  test('compares both modes over a concave polygon batch', () {
    BatchResult runTest(int hitboxCount) {
      final vertices = pathVertices(flamePath());
      final template = PolygonHitbox(
        vertices.map((vertex) => vertex.clone()).toList(),
      );
      final random = Random(0);
      final positions = [
        for (var index = 0; index < hitboxCount; index++)
          Vector2(
            random.nextDouble() * _testWidth,
            random.nextDouble() * _testHeight,
          ),
      ];
      final hitboxes = [
        for (var index = 0; index < hitboxCount; index++)
          PolygonHitbox(
            vertices.map((vertex) => vertex.clone()).toList(),
            position: positions[index].clone(),
          ),
      ];
      final rayCases = _randomRayCases(template, hitboxCount, Random(1));
      final rays = [
        for (var index = 0; index < hitboxCount; index++)
          Ray2(
            origin: rayCases[index].ray.origin + positions[index],
            direction: rayCases[index].ray.direction,
          ),
      ];
      final expectedHitCount = rayCases
          .where((rayCase) => rayCase.expectsHit)
          .length;

      int run({required bool useContainment}) {
        var hitCount = 0;
        for (var index = 0; index < hitboxes.length; index++) {
          if (hitboxes[index].rayIntersection(
                rays[index],
                useContainment: useContainment,
              ) !=
              null) {
            hitCount++;
          }
        }
        return hitCount;
      }

      final crossingsStopwatch = Stopwatch()..start();
      final crossingsHitCount = run(useContainment: false);
      crossingsStopwatch.stop();

      final containmentStopwatch = Stopwatch()..start();
      final containmentHitCount = run(useContainment: true);
      containmentStopwatch.stop();

      expect(crossingsHitCount, expectedHitCount);
      expect(containmentHitCount, expectedHitCount);
      expect(
        rays.map((ray) => ray.direction.toString()).toSet(),
        hasLength(hitboxCount),
      );
      expect(
        positions.map((position) => position.toString()).toSet(),
        hasLength(hitboxCount),
      );
      final result = (
        crossingsStopwatch.elapsedMicroseconds,
        containmentStopwatch.elapsedMicroseconds,
      );
      if (_verbose > 1) {
        print(
          'Concave PolygonRayIntersection: #${hitboxes.length} hitboxes, #${rays.length} rays, expected hits = $expectedHitCount -> crossings: ${result.$1}µs, containment: ${result.$2}µs',
        );
      }
      return result;
    }

    var crossings = 0;
    var containment = 0;
    const numRuns = 500;
    const count = 100;
    for (var index = 0; index < numRuns; ++index) {
      final result = runTest(count);
      crossings += result.$1;
      containment += result.$2;
    }
    final avgCrossings = crossings / numRuns;
    final avgContainment = containment / numRuns;
    if (_verbose > 0) {
      print(
        'Concave PolygonRayIntersection: #$numRuns runs == crossings: $crossingsµs ⨏:${avgCrossings.toStringAsFixed(1)}µs, containment: $containmentµs ⨏:${avgContainment.toStringAsFixed(1)}µs',
      );
    }
  });

  test('compares both modes over a convex polygon batch', () {
    BatchResult runTest(int hitboxCount) {
      final vertices = pathVertices(roundRectPath(const Size(64, 48)));
      final template = PolygonHitbox(
        vertices.map((vertex) => vertex.clone()).toList(),
      );
      final random = Random(0);
      final positions = [
        for (var index = 0; index < hitboxCount; index++)
          Vector2(
            random.nextDouble() * _testWidth,
            random.nextDouble() * _testHeight,
          ),
      ];
      final hitboxes = [
        for (var index = 0; index < hitboxCount; index++)
          PolygonHitbox(
            vertices.map((vertex) => vertex.clone()).toList(),
            position: positions[index].clone(),
          ),
      ];
      final rayCases = _randomRayCases(
        template,
        hitboxCount,
        Random(1),
        safePoint: template.size / 2,
      );
      final rays = [
        for (var index = 0; index < hitboxCount; index++)
          Ray2(
            origin: rayCases[index].ray.origin + positions[index],
            direction: rayCases[index].ray.direction,
          ),
      ];
      final expectedHitCount = rayCases
          .where((rayCase) => rayCase.expectsHit)
          .length;

      int run({required bool useContainment}) {
        var hitCount = 0;
        for (var index = 0; index < hitboxes.length; index++) {
          if (hitboxes[index].rayIntersection(
                rays[index],
                useContainment: useContainment,
              ) !=
              null) {
            hitCount++;
          }
        }
        return hitCount;
      }

      final crossingsStopwatch = Stopwatch()..start();
      final crossingsHitCount = run(useContainment: false);
      crossingsStopwatch.stop();

      final containmentStopwatch = Stopwatch()..start();
      final containmentHitCount = run(useContainment: true);
      containmentStopwatch.stop();

      expect(crossingsHitCount, expectedHitCount);
      expect(containmentHitCount, expectedHitCount);
      expect(
        rays.map((ray) => ray.direction.toString()).toSet(),
        hasLength(hitboxCount),
      );
      expect(
        positions.map((position) => position.toString()).toSet(),
        hasLength(hitboxCount),
      );
      final result = (
        crossingsStopwatch.elapsedMicroseconds,
        containmentStopwatch.elapsedMicroseconds,
      );
      if (_verbose > 1) {
        print(
          'Convex PolygonRayIntersection: #${hitboxes.length} hitboxes, #${rays.length} rays, expected hits = $expectedHitCount -> crossings: ${result.$1}µs, containment: ${result.$2}µs',
        );
      }
      return result;
    }

    var crossings = 0;
    var containment = 0;
    const numRuns = 500;
    const count = 100;
    for (var index = 0; index < numRuns; ++index) {
      final result = runTest(count);
      crossings += result.$1;
      containment += result.$2;
    }
    final avgCrossings = crossings / numRuns;
    final avgContainment = containment / numRuns;
    if (_verbose > 0) {
      print(
        'Convex PolygonRayIntersection: #$numRuns runs == crossings: $crossingsµs ⨏:${avgCrossings.toStringAsFixed(1)}µs, containment: $containmentµs ⨏:${avgContainment.toStringAsFixed(1)}µs',
      );
    }
  });
}
