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
    final stage = ((levelNumber - 1).clamp(0, 299)) ~/ 12;
    final presets = <TubeVisualStyle>[
      const TubeVisualStyle(
        design: TubeDesign.neon,
        borderColor: Color(0xFFF5FBFF),
        innerColor: Color(0xFF141442),
        selectionColor: Color(0xFFFFD54F),
        strokeWidth: 5.6,
        width: 86,
        height: 210,
        topPadding: 18,
        bottomPadding: 16,
        segmentGap: 4.2,
      ),
      const TubeVisualStyle(
        design: TubeDesign.neon,
        borderColor: Color(0xFFFDF4FF),
        innerColor: Color(0xFF1B164F),
        selectionColor: Color(0xFFFFEA80),
        strokeWidth: 5.8,
        width: 88,
        height: 214,
        topPadding: 18,
        bottomPadding: 17,
        segmentGap: 4.4,
      ),
      const TubeVisualStyle(
        design: TubeDesign.neon,
        borderColor: Color(0xFFF0E9FF),
        innerColor: Color(0xFF120F38),
        selectionColor: Color(0xFFFFC778),
        strokeWidth: 6.1,
        width: 90,
        height: 218,
        topPadding: 19,
        bottomPadding: 18,
        segmentGap: 4.6,
      ),
    ];

    final index = stage.clamp(0, presets.length - 1);
    final baseStyle = presets[index];
    final extraStage = math.max(0, stage - (presets.length - 1));
    if (extraStage == 0) {
      return baseStyle;
    }
    return baseStyle.copyWith(
      width: baseStyle.width + extraStage * 1.4,
      height: baseStyle.height + extraStage * 2.4,
      strokeWidth: baseStyle.strokeWidth + extraStage * 0.18,
      topPadding: baseStyle.topPadding + extraStage * 0.24,
      bottomPadding: baseStyle.bottomPadding + extraStage * 0.22,
      segmentGap: baseStyle.segmentGap + extraStage * 0.04,
    );
  }
}
