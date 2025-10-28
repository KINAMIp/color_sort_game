import 'dart:ui';

/// Describes a single segment of liquid inside a tube.
///
/// In addition to the color we store a couple of derived properties that are
/// useful for rendering more realistic liquid dynamics. The values are kept
/// lightweight so that we can create thousands of segments without affecting
/// performance.
class ColorSegment {
  ColorSegment(
    this.color, {
    double? viscosity,
    double? opacity,
  })  : viscosity = _clamp(viscosity ?? _estimateViscosity(color)),
        opacity = (opacity ?? 0.9).clamp(0.25, 1.0);

  final Color color;

  /// Viscosity is represented as a value in the range [0.12, 0.96]. Higher
  /// values indicate thicker liquids which in turn pour slightly slower and
  /// have smoother ripples.
  final double viscosity;

  /// Each segment can provide its own opacity so that transparent liquids can
  /// be rendered without having to duplicate colors. The painter uses the value
  /// when composing gradients and refraction highlights.
  final double opacity;

  /// A synthetic refractive index used to fake simple refraction highlights on
  /// the glass. The value is derived from viscosity because more viscous
  /// liquids often refract light differently.
  double get refractiveIndex => 1.08 + (0.96 - viscosity) * 0.18;

  static double _estimateViscosity(Color color) {
    // Darker and more saturated colors feel heavier, whereas bright pastel
    // liquids should flow faster. We approximate this by converting the color
    // to HSL and using saturation and lightness as the control parameters.
    final hsl = HSLColor.fromColor(color);
    final heaviness = (hsl.saturation * 0.7) + ((1 - hsl.lightness) * 0.6);
    return (0.18 + heaviness * 0.62).clamp(0.12, 0.96);
  }

  static double _clamp(double value) => value.clamp(0.12, 0.96);
}
