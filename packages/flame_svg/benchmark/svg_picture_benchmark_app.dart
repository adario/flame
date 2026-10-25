import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui show Image;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_svg/svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'picture_svg.dart';

/// The files of `examples/assets/svgs/` that are rendered, from a single
/// complex path to 28 paths, some of them with gradients.
const _files = [
  'invader1.svg',
  'happy_player.svg',
  'green_balloons.svg',
  'spaceship.svg',
  'flame.svg',
  'clover.svg',
];

const _counts = [100, 500, 1000];

/// The frames of the warmup are not measured.
const _warmup = Duration(seconds: 1);
const _measure = Duration(seconds: 4);

/// How long at least no new timings must come in before a case is done, since
/// the engine reports them in batches, every second in release mode.
const _drain = kReleaseMode
    ? Duration(milliseconds: 1200)
    : Duration(milliseconds: 300);

/// How long nothing is shown between two cases, so that the work left by a
/// case does not slow down the next one.
const _idle = Duration(seconds: 1);

/// The columns of the table of the cases, the times in milliseconds.
const _metrics = [
  'build',
  'raster',
  'interval',
  'interval p90',
  'fps',
  'missed',
  'load',
  'images/s',
];

/// How a case draws its SVG file: with `drawImage` from the cache of [Svg],
/// or with `drawPicture` from [PictureSvg].
enum _Renderer(final String label) {
  svg('Svg'),
  fixed('Svg fixed'),
  picture('Svg picture'),
}

/// What the camera does while the ring rotates.
enum _Scene() {
  ring,
  zoom,
}

/// Runs the cases one after the other in a [GameWidget], measures their
/// frames with [FrameTiming], prints a table and summaries, and exits.
///
/// From the `examples` directory, which has a macOS runner and bundles the
/// SVG files:
///
///     flutter run --profile -d macos -t ../packages/flame_svg/benchmark/svg_picture_benchmark_app.dart
///
/// The window must stay visible, or the frames stop: it may be behind other
/// windows, but not fully covered, minimized or on another space.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final game = ValueNotifier<FlameGame?>(null);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder(
        valueListenable: game,
        builder: (context, value, _) => value == null
            ? const SizedBox.shrink()
            : GameWidget(key: ObjectKey(value), game: value),
      ),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;

  final timings = <FrameTiming>[];
  SchedulerBinding.instance.addTimingsCallback(timings.addAll);
  var images = 0;
  var hidden = false;
  AppLifecycleListener(
    onStateChange: (state) => hidden |= !_showsFrames(state),
  );

  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final budget = Duration(
    microseconds: (Duration.microsecondsPerSecond / view.display.refreshRate)
        .round(),
  );
  const mode = kReleaseMode
      ? 'release'
      : kProfileMode
      ? 'profile'
      : 'debug';
  _print(
    'Svg drawImage vs drawPicture in a game ($mode), '
    '${view.physicalSize.width.toInt()}x${view.physicalSize.height.toInt()} '
    'physical pixels, ${view.display.refreshRate.toStringAsFixed(0)} Hz, '
    'frame budget ${_ms(budget.inMicroseconds)} ms',
  );
  _print(
    'A frame is missed when it comes more than 1.5 budgets after the previous '
    'one; * marks a case during which the window was hidden',
  );
  _print(
    '${'file'.padRight(20)}${'scene'.padRight(6)}${'n'.padLeft(5)}  '
    '${'renderer'.padRight(12)}'
    '${_cells(_metrics)}',
  );

  final results = <_Result>[];
  for (final file in _files) {
    final source = await rootBundle.loadString('assets/svgs/$file');
    for (final scene in _Scene.values) {
      for (final count in _counts) {
        for (final renderer in _Renderer.values) {
          final Svg? svg;
          final void Function(Canvas canvas, Vector2 size) draw;
          switch (renderer) {
            case _Renderer.svg || _Renderer.fixed:
              svg = await Svg.loadFromString(
                source,
                fixedRatio: renderer == _Renderer.fixed,
              );
              draw = svg.render;
            case _Renderer.picture:
              svg = null;
              draw = (await PictureSvg.loadFromString(source)).render;
          }

          final caseGame = _BenchmarkGame(draw, count: count, scene: scene);
          hidden = !_showsFrames(WidgetsBinding.instance.lifecycleState);
          game.value = caseGame;
          await caseGame.loaded;
          timings.clear();
          await Future<void>.delayed(_warmup);
          // Counts the images that Svg draws when it misses its cache.
          images = 0;
          ui.Image.onCreate = (_) => images++;
          await Future<void>.delayed(_measure);
          ui.Image.onCreate = null;
          game.value = null;
          await WidgetsBinding.instance.endOfFrame;
          await _settle(timings);
          svg?.dispose();

          final result = _Result.of(
            file: file,
            scene: scene,
            count: count,
            renderer: renderer,
            timings: timings,
            budget: budget,
            images: images,
            hidden: hidden,
          );
          results.add(result);
          _print(
            '${file.padRight(20)}${scene.name.padRight(6)}'
            '${count.toString().padLeft(5)}  ${renderer.label.padRight(12)}'
            '${_cells([
              _ms(result.build),
              _ms(result.raster),
              _ms(result.interval),
              _ms(result.intervalP90),
              result.fps.toStringAsFixed(1),
              '${result.missed.toStringAsFixed(1)}%',
              '${result.load.toStringAsFixed(1)}%',
              result.imagesPerSecond.toStringAsFixed(0),
            ])}'
            '${result.hidden ? ' *' : ''}',
          );
          await Future<void>.delayed(_idle);
        }
      }
    }
  }
  _printSummaries(results);
  exit(0);
}

/// Waits until the engine has reported the timings of all the frames of a
/// case, which a slow raster can delay by seconds, so that they do not end up
/// in the next case.
Future<void> _settle(List<FrameTiming> timings) async {
  final longest = timings
      .map((timing) => timing.rasterDuration)
      .fold(Duration.zero, (a, b) => a > b ? a : b);
  final quiet = _drain > longest * 2 ? _drain : longest * 2;
  int count;
  do {
    count = timings.length;
    await Future<void>.delayed(quiet);
  } while (timings.length != count);
}

/// Whether the frames are drawn in the given lifecycle [state].
bool _showsFrames(AppLifecycleState? state) =>
    state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

/// A ring of [count] components that rotate with staggered delays and shrink
/// along the ring, around a bigger one in the middle, like the testbed of
/// `flame_extended_svg`. With [_Scene.zoom], the camera also zooms in and
/// out.
class _BenchmarkGame(
  final void Function(Canvas canvas, Vector2 size) draw, {
  required final int count,
  required final _Scene scene,
}) extends FlameGame {
  static const _rotation = 2.0;
  static const _zoomPeriod = 4.0;

  var _time = 0.0;

  @override
  Future<void> onLoad() async {
    final side = min(size.x, size.y) / 4;
    final radius = (size.x + size.y) / 8;
    world.add(
      _SvgDrawer(
        draw,
        size: Vector2.all(side),
        anchor: Anchor.center,
        priority: count + 1,
      )..add(_rotate(0)),
    );
    world.addAll([
      for (var i = 0; i < count; i++)
        _SvgDrawer(
          draw,
          position: Vector2(cos(_angle(i)), sin(_angle(i)))..scale(radius),
          size: Vector2.all(side),
          scale: Vector2.all(1 - 0.75 * i / count),
          angle: _angle(i) + pi / 2,
          anchor: Anchor.center,
          priority: count - i,
        )..add(_rotate(_rotation / 2 * i / count)),
    ]);
  }

  double _angle(int i) => 2 * pi * (i + 1) / count;

  Effect _rotate(double delay) => RotateEffect.by(
    2 * pi,
    EffectController(duration: _rotation, startDelay: delay, infinite: true),
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (scene == _Scene.zoom) {
      _time += dt;
      // Between 0.5 and 2.
      camera.viewfinder.zoom = 1.25 + 0.75 * sin(2 * pi * _time / _zoomPeriod);
    }
  }
}

/// Draws an SVG file with [draw], which is the same for all the instances of
/// a case, at the size of the component.
class _SvgDrawer(
  final void Function(Canvas canvas, Vector2 size) draw, {
  super.position,
  super.size,
  super.scale,
  super.angle,
  super.anchor,
  super.priority,
}) extends PositionComponent {
  @override
  void render(Canvas canvas) => draw(canvas, size);
}

/// The measured frames of a case, with the times in microseconds.
class _Result({
  required this.file,
  required this.scene,
  required this.count,
  required this.renderer,
  required this.build,
  required this.raster,
  required this.interval,
  required this.intervalP90,
  required this.fps,
  required this.missed,
  required this.load,
  required this.imagesPerSecond,
  required this.hidden,
}) {
  /// Keeps the [timings] of the frames that started within [_measure] after
  /// [_warmup], counted from the first frame.
  factory _Result.of({
    required String file,
    required _Scene scene,
    required int count,
    required _Renderer renderer,
    required List<FrameTiming> timings,
    required Duration budget,
    required int images,
    required bool hidden,
  }) {
    final starts = [
      for (final timing in timings)
        timing.timestampInMicroseconds(FramePhase.vsyncStart),
    ];
    final first = starts.reduce(min) + _warmup.inMicroseconds;
    final last = first + _measure.inMicroseconds;
    final frames = [
      for (final (i, timing) in timings.indexed)
        if (starts[i] >= first && starts[i] < last) (starts[i], timing),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final intervals = [
      for (var i = 1; i < frames.length; i++) frames[i].$1 - frames[i - 1].$1,
    ];
    final late = budget.inMicroseconds * 1.5;
    return _Result(
      file: file,
      scene: scene,
      count: count,
      renderer: renderer,
      build: _mean([
        for (final (_, f) in frames) f.buildDuration.inMicroseconds,
      ]),
      raster: _mean([
        for (final (_, f) in frames) f.rasterDuration.inMicroseconds,
      ]),
      interval: _mean(intervals),
      intervalP90: _p90(intervals),
      fps: frames.length / (_measure.inMicroseconds / 1e6),
      missed: 100 * intervals.where((i) => i > late).length / intervals.length,
      load:
          100 *
          _mean([
            for (final (_, f) in frames)
              max(
                f.buildDuration.inMicroseconds,
                f.rasterDuration.inMicroseconds,
              ),
          ]) /
          budget.inMicroseconds,
      imagesPerSecond: images / (_measure.inMicroseconds / 1e6),
      hidden: hidden,
    );
  }

  final String file;
  final _Scene scene;
  final int count;
  final _Renderer renderer;
  final double build;
  final double raster;

  /// The time between the starts of two frames.
  final double interval;
  final double intervalP90;
  final double fps;

  /// The percentage of frames that came more than 1.5 frame budgets after the
  /// previous one.
  final double missed;

  /// The mean percentage of the frame budget taken by the longer of the build
  /// and the raster of a frame, which does not include the images that Svg
  /// draws outside of the frames.
  final double load;

  /// The images created per second, which Svg draws when it misses its cache.
  final double imagesPerSecond;

  /// Whether the window was hidden during the case, which stops the frames.
  final bool hidden;
}

/// NaN when a case has too few frames to measure.
double _mean(List<int> values) => values.isEmpty
    ? double.nan
    : values.reduce((a, b) => a + b) / values.length;

double _p90(List<int> values) {
  if (values.isEmpty) {
    return double.nan;
  }
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * 0.9).round()].toDouble();
}

void _printSummaries(List<_Result> results) {
  _Result find(String file, _Scene scene, int count, _Renderer renderer) =>
      results.firstWhere(
        (r) =>
            r.file == file &&
            r.scene == scene &&
            r.count == count &&
            r.renderer == renderer,
      );
  final columns = [for (final file in _files) file.replaceAll('.svg', '')];

  _print('');
  _print('Summary of the frames per second');
  _print(
    '${'scene'.padRight(6)}${'n'.padLeft(5)}  ${'renderer'.padRight(12)}'
    '${_cells(columns)}',
  );
  for (final scene in _Scene.values) {
    for (final count in _counts) {
      for (final renderer in _Renderer.values) {
        final fps = [
          for (final file in _files)
            switch (find(file, scene, count, renderer)) {
              final r => '${r.fps.toStringAsFixed(1)}${r.hidden ? '*' : ''}',
            },
        ];
        _print(
          '${scene.name.padRight(6)}${count.toString().padLeft(5)}  '
          '${renderer.label.padRight(12)}${_cells(fps)}',
        );
      }
    }
  }

  void printRatios(String title, double Function(_Result result) metric) {
    _print('');
    _print(title);
    _print(
      '${'scene'.padRight(6)}${'n'.padLeft(5)}  ${'vs'.padRight(12)}'
      '${_cells([...columns, 'geomean'])}',
    );
    for (final scene in _Scene.values) {
      for (final count in _counts) {
        for (final svg in [_Renderer.svg, _Renderer.fixed]) {
          final ratios = [
            for (final file in _files)
              metric(find(file, scene, count, _Renderer.picture)) /
                  metric(find(file, scene, count, svg)),
          ];
          _print(
            '${scene.name.padRight(6)}${count.toString().padLeft(5)}  '
            '${svg.label.padRight(12)}'
            '${_cells([...ratios, _geomean(ratios)].map(_ratio))}',
          );
        }
      }
    }
  }

  printRatios(
    'Summary of the frames per second of Svg picture / Svg, more than 1 when '
    'drawPicture is faster',
    (result) => result.fps,
  );
  printRatios(
    'Summary of the loads of Svg picture / Svg, less than 1 when drawPicture '
    'leaves more of the frame budget',
    (result) => result.load,
  );
}

double _geomean(List<double> ratios) =>
    exp(ratios.map(log).reduce((a, b) => a + b) / ratios.length);

String _ratio(double ratio) => ratio.toStringAsFixed(2);

/// Microseconds as milliseconds.
String _ms(num micros) => (micros / 1000).toStringAsFixed(2);

String _cells(Iterable<String> cells) =>
    cells.map((cell) => cell.padLeft(15)).join();

// ignore: avoid_print
void _print(String line) => print(line);
