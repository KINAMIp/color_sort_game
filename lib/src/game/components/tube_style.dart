import 'dart:math' as math;
import 'dart:ui';

enum TubeDesign { classic, slender, potion, royal, neon }

class TubeVisualStyle {
  const TubeVisualStyle({
    required this.design,
    required this.borderColor,
    required this.innerColor,
    required this.selectionColor,
    required this.strokeWidth,
    required this.width,
    required this.height,
    required this.topPadding,
    required this.bottomPadding,
    required this.segmentGap,
  });

  final TubeDesign design;
  final Color borderColor;
  final Color innerColor;
  final Color selectionColor;
  final double strokeWidth;
  final double width;
  final double height;
  final double topPadding;
  final double bottomPadding;
  final double segmentGap;

  TubeVisualStyle copyWith({
    TubeDesign? design,
    Color? borderColor,
    Color? innerColor,
    Color? selectionColor,
    double? strokeWidth,
    double? width,
    double? height,
    double? topPadding,
    double? bottomPadding,
    double? segmentGap,
  }) {
    return TubeVisualStyle(
      design: design ?? this.design,
      borderColor: borderColor ?? this.borderColor,
      innerColor: innerColor ?? this.innerColor,
      selectionColor: selectionColor ?? this.selectionColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      width: width ?? this.width,
      height: height ?? this.height,
      topPadding: topPadding ?? this.topPadding,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      segmentGap: segmentGap ?? this.segmentGap,
    );
  }

  static TubeVisualStyle forLevel(int levelNumber) {
    final stage = ((levelNumber - 1).clamp(0, 299)) ~/ 10;
    const patterns = <TubeVisualStyle>[
      TubeVisualStyle(
        design: TubeDesign.slender,
        borderColor: Color(0xFFE8F7FF),
        innerColor: Color(0x33214D7B),
        selectionColor: Color(0xFF5DD0FF),
        strokeWidth: 3.6,
        width: 68,
        height: 216,
        topPadding: 18,
        bottomPadding: 16,
        segmentGap: 3.8,
      ),
      TubeVisualStyle(
        design: TubeDesign.potion,
        borderColor: Color(0xFFFDF2E9),
        innerColor: Color(0x33274E56),
        selectionColor: Color(0xFFFFC172),
        strokeWidth: 3.8,
        width: 70,
        height: 222,
        topPadding: 18,
        bottomPadding: 18,
        segmentGap: 4.0,
      ),
      TubeVisualStyle(
        design: TubeDesign.royal,
        borderColor: Color(0xFFF4E8FF),
        innerColor: Color(0x332B1F5A),
        selectionColor: Color(0xFFB985FF),
        strokeWidth: 4.0,
        width: 72,
        height: 226,
        topPadding: 18,
        bottomPadding: 18,
        segmentGap: 4.0,
      ),
      TubeVisualStyle(
        design: TubeDesign.classic,
        borderColor: Color(0xFFE2FBF2),
        innerColor: Color(0x33163845),
        selectionColor: Color(0xFF74E3B6),
        strokeWidth: 3.6,
        width: 74,
        height: 228,
        topPadding: 18,
        bottomPadding: 18,
        segmentGap: 4.0,
      ),
      TubeVisualStyle(
        design: TubeDesign.neon,
        borderColor: Color(0xFFF5FBFF),
        innerColor: Color(0xFF141442),
        selectionColor: Color(0xFFFFD54F),
        strokeWidth: 4.2,
        width: 76,
        height: 232,
        topPadding: 18,
        bottomPadding: 18,
        segmentGap: 4.0,
      ),
      TubeVisualStyle(
        design: TubeDesign.potion,
        borderColor: Color(0xFFF7E8FF),
        innerColor: Color(0x33261653),
        selectionColor: Color(0xFF8DE1FF),
        strokeWidth: 4.0,
        width: 78,
        height: 236,
        topPadding: 18,
        bottomPadding: 18,
        segmentGap: 4.2,
      ),
    ];

    final patternIndex = stage % patterns.length;
    final iteration = stage ~/ patterns.length;
    final base = patterns[patternIndex];
    if (iteration == 0) {
      return base;
    }
    return base.copyWith(
      width: base.width + iteration * 2.2,
      height: base.height + iteration * 3.4,
      strokeWidth: base.strokeWidth + iteration * 0.24,
      topPadding: base.topPadding + iteration * 0.26,
      bottomPadding: base.bottomPadding + iteration * 0.24,
      segmentGap: base.segmentGap + iteration * 0.08,
      borderColor: Color.lerp(base.borderColor, const Color(0xFFE0F7FF), iteration / 3)!,
      selectionColor: Color.lerp(base.selectionColor, const Color(0xFFFFE082), iteration / 3)!,
    );
  }
}
