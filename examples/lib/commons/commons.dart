import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

mixin FpsText<W extends World> on FlameGame<W> {
  FpsTextComponent? _fpsText;

  Future<void> addFpsText() async {
    if (_fpsText != null) {
      return;
    }
    final size = camera.viewport.size;
    final position = Vector2(16, size.y - 24);
    _fpsText = FpsTextComponent(
      position: position,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
    camera.viewport.add(_fpsText!);
  }
}

class ExampleGame<W extends World> extends FlameGame<W> with FpsText<W> {
  ExampleGame({super.children, super.world, super.camera});

  @override
  void update(double dt) {
    super.update(dt);
    addFpsText();
  }
}

String baseLink(String path) {
  const basePath =
      'https://github.com/flame-engine/flame/blob/main/examples/lib/stories/';

  return '$basePath$path';
}
