import 'dart:math' as math;
import 'dart:ui';

enum TubeDesign { classic, slender, potion, royal }

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
    final presets = <TubeVisualStyle>[
      const TubeVisualStyle(
        design: TubeDesign.classic,
        borderColor: Color(0xFF1E88E5),
        innerColor: Color(0xFFE1F5FE),
        selectionColor: Color(0xFF00BCD4),
        strokeWidth: 4,
        width: 78,
        height: 198,
        topPadding: 16,
        bottomPadding: 14,
        segmentGap: 4,
      ),
      const TubeVisualStyle(
        design: TubeDesign.classic,
        borderColor: Color(0xFFAD1457),
        innerColor: Color(0xFFF8BBD0),
        selectionColor: Color(0xFFFF80AB),
        strokeWidth: 4.2,
        width: 80,
        height: 202,
        topPadding: 16,
        bottomPadding: 14,
        segmentGap: 4,
      ),
      const TubeVisualStyle(
        design: TubeDesign.classic,
        borderColor: Color(0xFF00897B),
        innerColor: Color(0xFFE0F2F1),
        selectionColor: Color(0xFF4DB6AC),
        strokeWidth: 4.2,
        width: 82,
        height: 204,
        topPadding: 17,
        bottomPadding: 15,
        segmentGap: 4,
      ),
      const TubeVisualStyle(
        design: TubeDesign.slender,
        borderColor: Color(0xFF283593),
        innerColor: Color(0xFFE8EAF6),
        selectionColor: Color(0xFF5C6BC0),
        strokeWidth: 4.4,
        width: 84,
        height: 210,
        topPadding: 18,
        bottomPadding: 15,
        segmentGap: 4.2,
      ),
      const TubeVisualStyle(
        design: TubeDesign.slender,
        borderColor: Color(0xFF6A1B9A),
        innerColor: Color(0xFFF3E5F5),
        selectionColor: Color(0xFFBA68C8),
        strokeWidth: 4.5,
        width: 86,
        height: 212,
        topPadding: 18,
        bottomPadding: 16,
        segmentGap: 4.5,
      ),
      const TubeVisualStyle(
        design: TubeDesign.potion,
        borderColor: Color(0xFF00695C),
        innerColor: Color(0xFFB2DFDB),
        selectionColor: Color(0xFF26A69A),
        strokeWidth: 4.6,
        width: 88,
        height: 214,
        topPadding: 20,
        bottomPadding: 16,
        segmentGap: 4.8,
      ),
      const TubeVisualStyle(
        design: TubeDesign.potion,
        borderColor: Color(0xFF4527A0),
        innerColor: Color(0xFFD1C4E9),
        selectionColor: Color(0xFFEFB7FF),
        strokeWidth: 4.8,
        width: 90,
        height: 216,
        topPadding: 20,
        bottomPadding: 17,
        segmentGap: 5,
      ),
      const TubeVisualStyle(
        design: TubeDesign.royal,
        borderColor: Color(0xFF283593),
        innerColor: Color(0xFFECEFF1),
        selectionColor: Color(0xFFFFD740),
        strokeWidth: 5,
        width: 90,
        height: 218,
        topPadding: 19,
        bottomPadding: 18,
        segmentGap: 5,
      ),
      const TubeVisualStyle(
        design: TubeDesign.royal,
        borderColor: Color(0xFF0D47A1),
        innerColor: Color(0xFFE3F2FD),
        selectionColor: Color(0xFFFFEB3B),
        strokeWidth: 5.2,
        width: 92,
        height: 220,
        topPadding: 20,
        bottomPadding: 18,
        segmentGap: 5,
      ),
      const TubeVisualStyle(
        design: TubeDesign.royal,
        borderColor: Color(0xFF311B92),
        innerColor: Color(0xFFEDE7F6),
        selectionColor: Color(0xFFFFF59D),
        strokeWidth: 5.4,
        width: 94,
        height: 222,
        topPadding: 20,
        bottomPadding: 18,
        segmentGap: 5.2,
      ),
    ];

    final index = stage.clamp(0, presets.length - 1);
    final baseStyle = presets[index];
    final extraStage = math.max(0, stage - (presets.length - 1));
    if (extraStage == 0) {
      return baseStyle;
    }
    final growth = 1 + extraStage * 0.03;
    return baseStyle.copyWith(
      width: baseStyle.width * (1 + extraStage * 0.015),
      height: baseStyle.height * growth,
      strokeWidth: baseStyle.strokeWidth + extraStage * 0.25,
      topPadding: baseStyle.topPadding + extraStage * 0.6,
      bottomPadding: baseStyle.bottomPadding + extraStage * 0.4,
      segmentGap: baseStyle.segmentGap + extraStage * 0.05,
    );
  }
}
