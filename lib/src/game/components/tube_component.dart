import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'color_segment.dart';

class TubeComponent extends PositionComponent with TapCallbacks {
  TubeComponent({
    required this.index,
    required this.capacity,
    required List<Color> initialColors,
    this.onTapped,
    Vector2? position,
    Vector2? size,
  })  : segments = initialColors.map(ColorSegment.new).toList(),
        super(position: position, size: size ?? Vector2(80, 200));

  final int index;
  final int capacity;
  final List<ColorSegment> segments;
  final void Function(TubeComponent component)? onTapped;

  bool _selected = false;

  bool get isSelected => _selected;

  set isSelected(bool value) {
    if (_selected != value) {
      _selected = value;
    }
  }

  bool get isEmpty => segments.isEmpty;

  bool get isFull => segments.length >= capacity;

  Color? get topColor => segments.isEmpty ? null : segments.last.color;

  int get consecutiveTopCount {
    if (segments.isEmpty) {
      return 0;
    }
    final top = segments.last.color;
    var count = 0;
    for (var i = segments.length - 1; i >= 0; i--) {
      if (segments[i].color == top) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool canPourTo(TubeComponent destination) {
    if (identical(this, destination)) {
      return false;
    }
    if (isEmpty || destination.isFull) {
      return false;
    }
    if (destination.isEmpty) {
      return true;
    }
    return destination.topColor == topColor;
  }

  List<ColorSegment> takeTopSegments(int amount) {
    final toTake = amount.clamp(0, segments.length);
    final removed = <ColorSegment>[];
    for (var i = 0; i < toTake; i++) {
      removed.add(segments.removeLast());
    }
    return removed;
  }

  void addSegments(List<ColorSegment> incoming) {
    segments.addAll(incoming);
  }

  bool containsPoint(Vector2 point) {
    final rect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    return rect.contains(point.toOffset());
  }

  List<ColorSegment> previewPourTo(TubeComponent destination) {
    if (!canPourTo(destination)) {
      return const <ColorSegment>[];
    }
    final movable = consecutiveTopCount;
    final space = destination.capacity - destination.segments.length;
    final moveCount = movable < space ? movable : space;
    return List<ColorSegment>.generate(
      moveCount,
      (_) => ColorSegment(topColor!),
    );
  }

  void handleTap() {
    onTapped?.call(this);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    handleTap();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = _selected ? const Color(0xFF42A5F5) : const Color(0xFF616161);
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0
      ..color = const Color(0xFFEEEEEE);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      borderPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(24)),
      fillPaint,
    );

    if (segments.isEmpty) {
      return;
    }

    final segmentHeight = (size.y - 16) / capacity;
    final segmentWidth = size.x - 16;
    final baseY = size.y - 8;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = segment.color;
      final top = baseY - (i + 1) * segmentHeight;
      final rect = Rect.fromLTWH(
        (size.x - segmentWidth) / 2,
        top,
        segmentWidth,
        segmentHeight - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        paint,
      );
    }
  }
}
