import 'dart:ui';

enum TubeDesign { cylindrical }

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
    return const TubeVisualStyle(
      design: TubeDesign.cylindrical,
      borderColor: Color(0xFFF3F6FF),
      innerColor: Color(0x1AFFFFFF),
      selectionColor: Color(0xFFFFC947),
      strokeWidth: 3.6,
      width: 86,
      height: 240,
      topPadding: 26,
      bottomPadding: 32,
      segmentGap: 4.0,
    );
  }
}
