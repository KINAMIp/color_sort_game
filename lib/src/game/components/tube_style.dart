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

  static TubeVisualStyle forLevel(int levelNumber) {
    if (levelNumber >= 201) {
      return const TubeVisualStyle(
        design: TubeDesign.royal,
        borderColor: Color(0xFF512DA8),
        innerColor: Color(0xFFF3E5F5),
        selectionColor: Color(0xFFFFD740),
        strokeWidth: 5,
        width: 80,
        height: 216,
        topPadding: 18,
        bottomPadding: 18,
        segmentGap: 5,
      );
    }
    if (levelNumber >= 151) {
      return const TubeVisualStyle(
        design: TubeDesign.potion,
        borderColor: Color(0xFF004D40),
        innerColor: Color(0xFFE0F2F1),
        selectionColor: Color(0xFFFFB300),
        strokeWidth: 4.5,
        width: 84,
        height: 212,
        topPadding: 20,
        bottomPadding: 16,
        segmentGap: 5,
      );
    }
    if (levelNumber >= 51) {
      return const TubeVisualStyle(
        design: TubeDesign.slender,
        borderColor: Color(0xFF1E88E5),
        innerColor: Color(0xFFE3F2FD),
        selectionColor: Color(0xFFFF7043),
        strokeWidth: 4,
        width: 82,
        height: 208,
        topPadding: 18,
        bottomPadding: 14,
        segmentGap: 4.5,
      );
    }
    return const TubeVisualStyle(
      design: TubeDesign.classic,
      borderColor: Color(0xFF616161),
      innerColor: Color(0xFFF5F5F5),
      selectionColor: Color(0xFF42A5F5),
      strokeWidth: 4,
      width: 80,
      height: 200,
      topPadding: 16,
      bottomPadding: 14,
      segmentGap: 4,
    );
  }
}
