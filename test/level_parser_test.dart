import 'package:flutter_test/flutter_test.dart';

import 'package:color_sort_game/src/data/level_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Level asset parses correctly', () async {
    final level = await LevelBundle.loadLevel('001');
    expect(level.id, '001');
    expect(level.tubeCapacity, 4);
    expect(level.tubes.first.length, 4);
  });
}
