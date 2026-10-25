# flame_svg benchmarks

`svg_game_benchmark_app.dart` compares `Svg` and `SvgPaths` in a game, by
drawing frames in a `GameWidget` like a real game does, and measuring them
with the `FrameTiming` that the engine reports.

Each case shows the scene of the
[flame_extended_svg](https://github.com/adario/flame_extended_svg)
testbed: a ring of 100, 500 or 1000 components that rotate with staggered
delays and shrink along the ring, around a bigger one in the middle. In the
`zoom` scene, the camera also zooms in and out between 0.5 and 2. All the
components of a case draw the same SVG file, at the same size, in one of three
ways:

- `Svg`: an `Svg` with its default cache, which draws its picture into a new
  image whenever the size on screen changes, so also when the components
  rotate, shrink or zoom.
- `Svg fixed`: an `Svg` with `fixedRatio`, which draws its picture into a
  single image, and then scales that image, so it can look blurry.
- `SvgPaths`: an `SvgPaths`, which draws all of its paths in every frame.

Each case runs for a second before its frames are measured for 4 seconds, and
prints:

- `build` and `raster`: the mean milliseconds of the build of a frame on the UI
  thread, and of its raster on the raster thread.
- `interval` and `interval p90`: the mean and the 90th percentile of the
  milliseconds between the starts of two frames.
- `fps`: the frames per second.
- `missed`: the percentage of frames that came more than 1.5 frame budgets
  after the previous one.
- `load`: the mean percentage of the frame budget taken by the longer of the
  build and the raster of a frame.
- `images/s`: the images created per second, which are the ones that `Svg`
  draws when it misses its cache.

Once all the cases are done, summaries list, for each file, the frames per
second of each renderer, the frames per second of `SvgPaths` divided by those
of `Svg`, and the loads of `SvgPaths` divided by those of `Svg`.

Some limits of the measures:

- The frames per second cannot go above the refresh rate of the display, so
  two renderers that both reach it have a ratio of 1. The loads show how much
  of the frame budget each one leaves.
- The raster of a frame is the work of the raster thread, not the time that
  the GPU takes to execute it.
- The images that `Svg` draws when it misses its cache are drawn outside of
  the frames, so they are not in the `build`, `raster` and `load` of `Svg`,
  but they slow down its frames per second.
- The numbers depend on the size of the window, which is printed at the start.


## Running

The benchmark runs as an app in a profile or release build, from the
`examples` directory, which has a macOS runner and bundles the SVG files:

```console
cd examples
flutter run --profile -d macos -t ../packages/flame_svg/benchmark/svg_game_benchmark_app.dart
```

Or, to run the binary directly:

```console
cd examples
flutter build macos --profile -t ../packages/flame_svg/benchmark/svg_game_benchmark_app.dart
build/macos/Build/Products/Profile/examples.app/Contents/MacOS/examples
```

The app prints the tables and exits when it is done, after about 12 minutes.
Use `--release` instead of `--profile` for a release build, where the frame
timings are reported once per second instead of 10 times.

The window must stay visible while the benchmark runs. It can be behind other
windows, but when it is fully covered, minimized, or on another space, macOS
reports it as hidden, and the frames stop. A case during which the window was
hidden is marked with `*`. Do not resize the window during a run.
