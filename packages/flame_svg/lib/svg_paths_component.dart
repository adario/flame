import 'dart:math' show min;
import 'dart:ui' show Paint, PaintingStyle;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart' show BasicPalette;
import 'package:flame_svg/flame_svg.dart';

/// A position component representing a whole SVG file.
class SvgPathsComponent extends PositionComponent {
  /// Create from the given [svg].
  SvgPathsComponent(
    this.svg, {
    bool? renderHitboxes,
    bool? filter,
    Vector2? size,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.key,
  }) : super(
         size: size ?? svg.bounds.size.toVector2(),
         children: createPathComponents(
           svg,
           size,
           renderHitboxes: renderHitboxes,
           filter: filter,
         ),
       );

  /// Load an [SvgPaths] object from the given [svgName], and create
  /// an [SvgPathsComponent] from it.
  static Future<SvgPathsComponent> load(
    String svgName, {
    String? assetsPath,
    bool? renderHitboxes,
    bool? filter,
    Vector2? position,
    Vector2? size,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    int? priority,
    ComponentKey? key,
  }) async {
    final svgFilename = '$svgName.svg';
    final svgPathName = (assetsPath ?? 'assets/svgs/') + svgFilename;
    final svg = await SvgPaths.fromFile(svgPathName, merge: false);
    return SvgPathsComponent(
      svg,
      renderHitboxes: renderHitboxes,
      filter: filter,
      position: position,
      size: size,
      scale: scale,
      angle: angle,
      anchor: anchor,
      priority: priority,
      key: key,
    );
  }

  /// The SVG file.
  final SvgPaths svg;

  // Temporary.
  static final _whiteStroke = Paint()
    ..color = const Color(0xffffffff)
    ..style = PaintingStyle.stroke;

  // Temporary.
  static final _pathStroke = Paint()
    ..color = BasicPalette.blue.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = .round
    ..strokeJoin = .bevel;

  /// Creates a [PathComponent] for each path in the [svg].
  ///
  /// The paths are scaled to fit within the [size] of the component while
  /// keeping the aspect ratio, and are centered within it. This way the
  /// center of the component is the center of the SVG contents, which is what
  /// the component rotates and scales around.
  static List<PathComponent> createPathComponents(
    SvgPaths svg,
    Vector2? size, {
    bool? renderHitboxes,
    bool? filter,
  }) {
    final full = svg.bounds;
    final fullSize = full.size.toVector2();
    final target = size ?? fullSize;
    final fit = min(target.x / fullSize.x, target.y / fullSize.y);
    final offset = (target - fullSize * fit) / 2;
    final paths = <PathComponent>[];
    final length = svg.length;
    for (var svgIndex = 0; svgIndex < length; ++svgIndex) {
      final vectorPath = svg.pathAt(svgIndex);
      final vectorPaints = svg.paintAt(svgIndex);
      assert(
        vectorPath != null && vectorPaints != null,
        'Invalid path or paints',
      );
      final path = vectorPath!.path;
      // A PathComponent moves its path to the origin, so we restore its
      // position within the SVG.
      final position =
          (path.getBounds().topLeft - full.topLeft).toVector2() * fit + offset;
      final paint = vectorPaints!.paint;
      final hitbox = PathHitbox(path: path, filter: filter ?? true);
      if (renderHitboxes ?? false) {
        hitbox
          ..renderShape = true
          ..paint = _whiteStroke;
      }
      paths.add(
        PathComponent(
          path: path,
          position: position,
          scale: Vector2.all(fit),
          paint: paint ?? _pathStroke,
          paintLayers: vectorPaints.paintLayers,
          filter: filter ?? true,
          children: [hitbox],
        ),
      );
    }
    return paths;
  }
}
