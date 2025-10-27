import 'package:color_sort_game/src/game/components/tube_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Tube can pour when colors match and space exists', () {
    final source = TubeComponent(
      index: 0,
      capacity: 4,
      initialColors: const [Colors.blue, Colors.blue],
    );
    final destination = TubeComponent(
      index: 1,
      capacity: 4,
      initialColors: const [Colors.blue],
    );
    expect(source.canPourTo(destination), isTrue);
  });

  test('Tube cannot pour into full tube', () {
    final source = TubeComponent(
      index: 0,
      capacity: 4,
      initialColors: const [Colors.green],
    );
    final destination = TubeComponent(
      index: 1,
      capacity: 2,
      initialColors: const [Colors.green, Colors.green],
    );
    expect(source.canPourTo(destination), isFalse);
  });
}
