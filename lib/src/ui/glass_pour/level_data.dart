import 'package:flutter/material.dart';

import 'models.dart';

const _palette = [
  Color(0xFFFF5252),
  Color(0xFF40C4FF),
  Color(0xFFFFEB3B),
  Color(0xFF69F0AE),
  Color(0xFFF06292),
  Color(0xFFFFAB91),
  Color(0xFF7C4DFF),
  Color(0xFF00BFA5),
  Color(0xFFA7FFEB),
  Color(0xFFEA80FC),
];

List<Color?> _layers(List<int> indices) {
  return indices.map((index) => _palette[index % _palette.length]).toList();
}

final List<GlassLevel> glassLevels = [
  GlassLevel(
    index: 1,
    allowedMoves: 10,
    tubes: [
      _layers([0, 1, 2, 3, 4]),
      _layers([4, 2, 3, 1, 0]),
      _layers([5, 3, 6, 2, 7]),
      [..._layers([1, 5, 4, 6]), null],
      [..._layers([7, 8, 9, 3]), null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 2,
    allowedMoves: 12,
    tubes: [
      _layers([0, 2, 4, 6, 8]),
      _layers([9, 7, 5, 3, 1]),
      [..._layers([6, 8, 2, 0]), null],
      [..._layers([4, 5, 1, 3]), null],
      [..._layers([7, 9, 0, 2]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 3,
    allowedMoves: 14,
    tubes: [
      _layers([5, 4, 3, 2, 1]),
      _layers([9, 8, 7, 6, 5]),
      [..._layers([0, 1, 2, 3]), null],
      [..._layers([4, 6, 8, 0]), null],
      [..._layers([7, 5, 3, 1]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 4,
    allowedMoves: 16,
    tubes: [
      _layers([0, 9, 8, 7, 6]),
      _layers([1, 2, 3, 4, 5]),
      [..._layers([2, 4, 6, 8]), null],
      [..._layers([5, 3, 1, 9]), null],
      [..._layers([7, 0, 2, 5]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 5,
    allowedMoves: 18,
    tubes: [
      _layers([4, 3, 2, 1, 0]),
      _layers([5, 6, 7, 8, 9]),
      [..._layers([0, 2, 4, 6]), null],
      [..._layers([3, 5, 7, 9]), null],
      [..._layers([1, 8, 6, 4]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 6,
    allowedMoves: 20,
    tubes: [
      _layers([0, 2, 5, 7, 9]),
      _layers([1, 3, 6, 8, 0]),
      [..._layers([4, 6, 9, 1]), null],
      [..._layers([2, 5, 7, 0]), null],
      [..._layers([3, 8, 4, 6]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 7,
    allowedMoves: 22,
    tubes: [
      _layers([2, 4, 6, 8, 0]),
      _layers([1, 3, 5, 7, 9]),
      [..._layers([0, 5, 3, 1]), null],
      [..._layers([6, 8, 2, 4]), null],
      [..._layers([7, 9, 1, 3]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 8,
    allowedMoves: 24,
    tubes: [
      _layers([8, 6, 4, 2, 0]),
      _layers([9, 7, 5, 3, 1]),
      [..._layers([2, 3, 4, 5]), null],
      [..._layers([6, 7, 8, 9]), null],
      [..._layers([0, 1, 2, 3]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 9,
    allowedMoves: 26,
    tubes: [
      _layers([9, 5, 1, 6, 2]),
      _layers([8, 4, 0, 5, 1]),
      [..._layers([7, 3, 9, 2]), null],
      [..._layers([6, 1, 8, 3]), null],
      [..._layers([5, 0, 7, 4]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
  GlassLevel(
    index: 10,
    allowedMoves: 28,
    tubes: [
      _layers([0, 1, 2, 3, 4]),
      _layers([5, 6, 7, 8, 9]),
      [..._layers([1, 3, 5, 7]), null],
      [..._layers([2, 4, 6, 8]), null],
      [..._layers([0, 2, 4, 6]), null],
      [null, null, null, null, null],
      [null, null, null, null, null],
      [null, null, null, null, null],
    ],
  ),
];
