import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Like `Svg`, but draws its picture with [Canvas.drawPicture] whenever it is
/// rendered, instead of drawing images of it into a cache. Only meant for the
/// benchmarks.
class PictureSvg(final PictureInfo pictureInfo) {
  /// Loads a [PictureSvg] from a string.
  static Future<PictureSvg> loadFromString(String svgString) async {
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    return PictureSvg(pictureInfo);
  }

  /// Renders the svg on the [canvas] using the dimensions provided by [size],
  /// where `Svg` would draw it.
  void render(Canvas canvas, Vector2 size) {
    final scale = math.min(
      size.x / pictureInfo.size.width,
      size.y / pictureInfo.size.height,
    );
    canvas.save();
    canvas.translate(
      (size.x - pictureInfo.size.width * scale) / 2,
      (size.y - pictureInfo.size.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
  }
}
