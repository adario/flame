import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';

/// The shapes used by the path contour benchmark, mirroring the ones in the
/// `flame_path_shapes` testbed.
const pathContourShapeNames = [
  'roundRect',
  'flame',
  'invader1',
  'invader2',
  'invader3',
];

Path pathContourShape(int index, Size size) {
  final Path path;
  switch (index) {
    case 0:
      return roundRectPath(size).centered;
    case 1:
      path = flamePath();
    case 2:
      path = invader1Path();
    case 3:
      path = invader2Path();
    case 4:
      path = invader3Path();
    default:
      throw ArgumentError.value(index, 'index', 'Unknown shape');
  }
  return path.resizeTo(size, keepRatio: true).centered;
}

Path roundRectPath(Size size) {
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(min(size.width, size.height) * 0.25),
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

Path invader1Path() {
  return Path()
    ..moveTo(415.915, 219.208)
    ..lineTo(415.915, 123.169)
    ..lineTo(344.69, 123.169)
    ..lineTo(344.69, 58.435)
    ..lineTo(311.299, 58.435)
    ..lineTo(311.299, 123.17)
    ..lineTo(200.701, 123.17)
    ..lineTo(200.701, 58.435)
    ..lineTo(167.31, 58.435)
    ..lineTo(167.31, 123.17)
    ..lineTo(96.085, 123.17)
    ..lineTo(96.085, 219.209)
    ..lineTo(0.0, 219.209)
    ..lineTo(0.0, 330.872)
    ..lineTo(33.391, 330.872)
    ..lineTo(33.391, 252.6)
    ..lineTo(96.084, 252.6)
    ..lineTo(96.084, 347.567)
    ..lineTo(167.31, 347.567)
    ..lineTo(167.31, 420.174)
    ..lineTo(136.522, 420.174)
    ..lineTo(136.522, 453.565)
    ..lineTo(200.701, 453.565)
    ..lineTo(200.701, 347.568)
    ..lineTo(311.299, 347.568)
    ..lineTo(311.299, 453.565)
    ..lineTo(375.478, 453.565)
    ..lineTo(375.478, 420.174)
    ..lineTo(344.69, 420.174)
    ..lineTo(344.69, 347.568)
    ..lineTo(415.916, 347.568)
    ..lineTo(415.916, 252.601)
    ..lineTo(478.608, 252.601)
    ..lineTo(478.608, 330.872)
    ..lineTo(512.0, 330.872)
    ..lineTo(512.0, 219.208)
    ..lineTo(415.915, 219.208)
    ..close();
}

Path invader2Path() {
  return Path()
    ..moveTo(31.0, 16.0)
    ..lineTo(29.0, 16.0)
    ..lineTo(29.0, 14.0)
    ..cubicTo(29.0, 13.4, 28.6, 13.0, 28.0, 13.0)
    ..lineTo(26.0, 13.0)
    ..lineTo(26.0, 11.0)
    ..cubicTo(26.0, 10.4, 25.6, 10.0, 25.0, 10.0)
    ..lineTo(23.0, 10.0)
    ..lineTo(23.0, 8.0)
    ..lineTo(25.0, 8.0)
    ..cubicTo(25.6, 8.0, 26.0, 7.6, 26.0, 7.0)
    ..lineTo(26.0, 4.0)
    ..cubicTo(26.0, 3.4, 25.6, 3.0, 25.0, 3.0)
    ..lineTo(22.0, 3.0)
    ..cubicTo(21.4, 3.0, 21.0, 3.4, 21.0, 4.0)
    ..lineTo(21.0, 6.0)
    ..lineTo(19.0, 6.0)
    ..cubicTo(18.4, 6.0, 18.0, 6.4, 18.0, 7.0)
    ..lineTo(18.0, 10.0)
    ..lineTo(14.0, 10.0)
    ..lineTo(14.0, 7.0)
    ..cubicTo(14.0, 6.4, 13.6, 6.0, 13.0, 6.0)
    ..lineTo(11.0, 6.0)
    ..lineTo(11.0, 4.0)
    ..cubicTo(11.0, 3.4, 10.6, 3.0, 10.0, 3.0)
    ..lineTo(7.0, 3.0)
    ..cubicTo(6.4, 3.0, 6.0, 3.4, 6.0, 4.0)
    ..lineTo(6.0, 7.0)
    ..cubicTo(6.0, 7.6, 6.4, 8.0, 7.0, 8.0)
    ..lineTo(9.0, 8.0)
    ..lineTo(9.0, 10.0)
    ..lineTo(7.0, 10.0)
    ..cubicTo(6.4, 10.0, 6.0, 10.4, 6.0, 11.0)
    ..lineTo(6.0, 13.0)
    ..lineTo(4.0, 13.0)
    ..cubicTo(3.4, 13.0, 3.0, 13.4, 3.0, 14.0)
    ..lineTo(3.0, 16.0)
    ..lineTo(1.0, 16.0)
    ..cubicTo(0.4, 16.0, 0.0, 16.4, 0.0, 17.0)
    ..lineTo(0.0, 26.0)
    ..cubicTo(0.0, 26.6, 0.4, 27.0, 1.0, 27.0)
    ..lineTo(4.0, 27.0)
    ..cubicTo(4.6, 27.0, 5.0, 26.6, 5.0, 26.0)
    ..lineTo(5.0, 21.0)
    ..lineTo(6.0, 21.0)
    ..lineTo(6.0, 26.0)
    ..cubicTo(6.0, 26.6, 6.4, 27.0, 7.0, 27.0)
    ..lineTo(9.0, 27.0)
    ..lineTo(9.0, 29.0)
    ..cubicTo(9.0, 29.6, 9.4, 30.0, 10.0, 30.0)
    ..lineTo(14.0, 30.0)
    ..cubicTo(14.6, 30.0, 15.0, 29.6, 15.0, 29.0)
    ..lineTo(15.0, 26.0)
    ..cubicTo(15.0, 25.4, 14.6, 25.0, 14.0, 25.0)
    ..lineTo(11.0, 25.0)
    ..lineTo(11.0, 24.0)
    ..lineTo(21.0, 24.0)
    ..lineTo(21.0, 25.0)
    ..lineTo(18.0, 25.0)
    ..cubicTo(17.4, 25.0, 17.0, 25.4, 17.0, 26.0)
    ..lineTo(17.0, 29.0)
    ..cubicTo(17.0, 29.6, 17.4, 30.0, 18.0, 30.0)
    ..lineTo(22.0, 30.0)
    ..cubicTo(22.6, 30.0, 23.0, 29.6, 23.0, 29.0)
    ..lineTo(23.0, 27.0)
    ..lineTo(25.0, 27.0)
    ..cubicTo(25.6, 27.0, 26.0, 26.6, 26.0, 26.0)
    ..lineTo(26.0, 21.0)
    ..lineTo(27.0, 21.0)
    ..lineTo(27.0, 26.0)
    ..cubicTo(27.0, 26.6, 27.4, 27.0, 28.0, 27.0)
    ..lineTo(31.0, 27.0)
    ..cubicTo(31.6, 27.0, 32.0, 26.6, 32.0, 26.0)
    ..lineTo(32.0, 17.0)
    ..cubicTo(32.0, 16.4, 31.6, 16.0, 31.0, 16.0)
    ..close();
}

Path invader3Path() {
  return Path()
    ..moveTo(21.0, 21.0002)
    ..cubicTo(25.4053, 42.1216, 29.3148, 65.4173, 32.4562, 90.1782)
    ..lineTo(108.684, 90.1782)
    ..lineTo(108.684, 138.5)
    ..lineTo(53.3124, 138.5)
    ..cubicTo(60.9409, 164.622, 65.9158, 202.214, 66.678, 244.691)
    ..lineTo(107.95, 244.691)
    ..lineTo(107.95, 275.975)
    ..lineTo(66.3842, 275.975)
    ..cubicTo(66.2285, 280.864, 66.2105, 285.634, 65.9439, 290.369)
    ..lineTo(107.95, 290.369)
    ..lineTo(107.95, 321.653)
    ..lineTo(63.1533, 321.653)
    ..cubicTo(60.8121, 341.683, 57.4724, 359.403, 53.3127, 373.647)
    ..lineTo(108.685, 373.647)
    ..lineTo(108.685, 421.969)
    ..lineTo(32.4564, 421.969)
    ..cubicTo(29.315, 446.73, 25.4055, 469.878, 21.0002, 491.0)
    ..cubicTo(67.2675, 482.246, 122.083, 476.073, 181.975, 473.228)
    ..lineTo(181.975, 421.969)
    ..lineTo(181.975, 373.647)
    ..lineTo(217.078, 373.647)
    ..cubicTo(224.884, 443.739, 239.294, 491.0, 256.0, 491.0)
    ..cubicTo(272.706, 491.0, 287.246, 443.739, 295.069, 373.647)
    ..lineTo(330.172, 373.647)
    ..lineTo(330.172, 421.969)
    ..lineTo(330.172, 473.228)
    ..cubicTo(390.064, 476.074, 444.733, 482.246, 491.0, 491.0)
    ..cubicTo(486.595, 469.878, 482.832, 446.73, 479.691, 421.969)
    ..lineTo(403.462, 421.969)
    ..lineTo(403.462, 373.647)
    ..lineTo(458.834, 373.647)
    ..cubicTo(454.675, 359.403, 451.262, 341.683, 448.847, 321.653)
    ..lineTo(404.05, 321.653)
    ..lineTo(404.05, 290.369)
    ..lineTo(446.056, 290.369)
    ..cubicTo(445.777, 285.634, 445.632, 280.864, 445.469, 275.975)
    ..lineTo(404.05, 275.975)
    ..lineTo(404.05, 244.691)
    ..lineTo(445.175, 244.691)
    ..cubicTo(445.977, 202.214, 451.206, 164.622, 458.834, 138.5)
    ..lineTo(403.463, 138.5)
    ..lineTo(403.463, 90.1782)
    ..lineTo(479.691, 90.1782)
    ..cubicTo(482.832, 65.4173, 486.595, 42.1216, 491.0, 21.0002)
    ..cubicTo(444.733, 29.7544, 390.064, 36.0734, 330.172, 38.9189)
    ..lineTo(330.172, 138.5)
    ..lineTo(295.069, 138.5)
    ..cubicTo(287.245, 68.3814, 272.708, 21.0002, 256.0, 21.0002)
    ..cubicTo(239.293, 21.0002, 224.885, 68.3814, 217.078, 138.5)
    ..lineTo(181.975, 138.5)
    ..lineTo(181.975, 38.9189)
    ..cubicTo(122.083, 36.0733, 67.2678, 29.7544, 21.0004, 21.0002)
    ..lineTo(21.0, 21.0002)
    ..close();
}
