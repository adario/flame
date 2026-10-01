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
         children: [
           createContent(
             svg,
             size,
             renderHitboxes: renderHitboxes,
             filter: filter,
           ),
         ],
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

  /// Creates the content of the component: a container with the size of the
  /// bounds of the whole SVG, centered and scaled to fit within the [size] of
  /// the component while keeping the aspect ratio. This keeps the [size] of
  /// the component as requested, and rotates and scales it around the center
  /// of the SVG contents.
  static PositionComponent createContent(
    SvgPaths svg,
    Vector2? size, {
    bool? renderHitboxes,
    bool? filter,
  }) {
    final full = svg.bounds;
    final fullSize = full.size.toVector2();
    final target = size ?? fullSize;
    final fit = min(target.x / fullSize.x, target.y / fullSize.y);
    return PositionComponent(
      size: fullSize,
      position: target / 2,
      anchor: Anchor.center,
      scale: Vector2.all(fit),
      children: createPathComponents(
        svg,
        full,
        renderHitboxes: renderHitboxes,
        filter: filter,
      ),
    );
  }

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

  /// Creates a [PathComponent] for each path in the [svg], positioned
  /// relative to the top left corner of the [full] bounds of the SVG.
  static List<PathComponent> createPathComponents(
    SvgPaths svg,
    Rect full, {
    bool? renderHitboxes,
    bool? filter,
  }) {
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
      final position = path.getBounds().topLeft - full.topLeft;
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
          position: position.toVector2(),
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
