import 'package:color_sort_game/src/game/components/tube_component.dart';
import 'package:color_sort_game/src/game/components/tube_style.dart';
import 'package:color_sort_game/src/game/systems/pour_system.dart';
import 'package:color_sort_game/src/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAudioService extends AudioService {
  @override
  void playInvalid() {}

  @override
  void playPour() {}

  @override
  void playWin() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PourSystem moves top matching segments', () async {
    final style = TubeVisualStyle.forLevel(1);
    final source = TubeComponent(
      index: 0,
      capacity: 4,
      initialColors: const [Colors.red, Colors.red, Colors.blue],
      style: style,
    );
    final destination = TubeComponent(
      index: 1,
      capacity: 4,
      initialColors: const [Colors.red],
      style: style,
    );

    final system = PourSystem(
      audioService: _FakeAudioService(),
    );

    final result = await system.tryPour(source: source, destination: destination);
    expect(result, isTrue);
    expect(source.segments.length, 1);
    expect(destination.segments.length, 3);
    expect(destination.segments.last.color, Colors.red);
  });
}
