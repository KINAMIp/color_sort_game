import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'level_data.dart';
import 'models.dart';
import 'pour_animation.dart';
import 'tube_widget.dart';

class GlassPourGameScreen extends StatefulWidget {
  const GlassPourGameScreen({super.key});

  @override
  State<GlassPourGameScreen> createState() => _GlassPourGameScreenState();
}

class _GlassPourGameScreenState extends State<GlassPourGameScreen>
    with TickerProviderStateMixin {
  late GlassLevel _level;
  late List<TubeState> _tubes;
  List<AnimationController> _waveControllers = [];
  late AnimationController _shimmerController;
  late AnimationController _counterPulseController;

  final List<GlobalKey> _tubeKeys = [];
  final GlobalKey _stackKey = GlobalKey();
  int _currentLevelIndex = 0;
  int _movesRemaining = 0;
  int? _selectedTubeIndex;
  bool _isPouring = false;
  ActivePourState? _activePour;
  double? _incomingFillProgress;
  int? _incomingFillTargetIndex;
  Color? _incomingFillColor;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _counterPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0,
      upperBound: 1,
    );

    _loadLevel(0);
  }

  @override
  void dispose() {
    for (final controller in _waveControllers) {
      controller.dispose();
    }
    _shimmerController.dispose();
    _counterPulseController.dispose();
    _activePour?.controller.dispose();
    super.dispose();
  }

  void _loadLevel(int index) {
    if (mounted && _waveControllers.isNotEmpty) {
      for (final controller in _waveControllers) {
        controller.dispose();
      }
    }
    final level = glassLevels[index % glassLevels.length];
    _level = level;
    _movesRemaining = level.allowedMoves;
    _tubes = level.tubes
        .map((layers) => TubeState(List<Color?>.from(layers)))
        .toList();
    _waveControllers = List.generate(_tubes.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      );
    });
    _tubeKeys
      ..clear()
      ..addAll(List.generate(_tubes.length, (_) => GlobalKey()));
    setState(() {
      _selectedTubeIndex = null;
      _isPouring = false;
      _activePour?.controller.dispose();
      _activePour = null;
      _incomingFillColor = null;
      _incomingFillProgress = null;
      _incomingFillTargetIndex = null;
    });
  }

  void _onTubeTap(int index) {
    if (_isPouring) {
      return;
    }
    if (_movesRemaining == 0) {
      _counterPulseController
        ..reset()
        ..forward();
      return;
    }

    final tube = _tubes[index];
    if (_selectedTubeIndex == null) {
      if (tube.isEmpty) {
        return;
      }
      setState(() => _selectedTubeIndex = index);
      return;
    }

    if (_selectedTubeIndex == index) {
      setState(() => _selectedTubeIndex = null);
      return;
    }

    final source = _tubes[_selectedTubeIndex!];
    final target = _tubes[index];
    if (source.isEmpty) {
      setState(() => _selectedTubeIndex = null);
      return;
    }

    if (!target.hasSpaceFor(source.topColor)) {
      setState(() => _selectedTubeIndex = null);
      return;
    }

    _performPour(sourceIndex: _selectedTubeIndex!, targetIndex: index);
  }

  void _performPour({required int sourceIndex, required int targetIndex}) {
    final source = _tubes[sourceIndex];
    final target = _tubes[targetIndex];
    final color = source.removeTopColor();
    if (color == null) {
      setState(() => _selectedTubeIndex = null);
      return;
    }

    final targetSlotIndex = target.nextFillSlot;
    if (targetSlotIndex == null) {
      source.restoreColor(color);
      setState(() => _selectedTubeIndex = null);
      return;
    }

    final sourceBox =
        _tubeKeys[sourceIndex].currentContext?.findRenderObject() as RenderBox?;
    final targetBox =
        _tubeKeys[targetIndex].currentContext?.findRenderObject() as RenderBox?;
    if (sourceBox == null || targetBox == null) {
      source.restoreColor(color);
      setState(() => _selectedTubeIndex = null);
      return;
    }

    final sourceOffset = sourceBox.localToGlobal(Offset.zero);
    final targetOffset = targetBox.localToGlobal(Offset.zero);
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) {
      source.restoreColor(color);
      setState(() => _selectedTubeIndex = null);
      return;
    }

    final startCenter = stackBox.globalToLocal(
      sourceOffset + Offset(sourceBox.size.width / 2, 12),
    );
    final endCenter = stackBox.globalToLocal(
      targetOffset + Offset(targetBox.size.width / 2, 12),
    );

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    controller.addListener(() {
      final progress = controller.value;
      setState(() {
        if (progress > 0.66) {
          _incomingFillColor = color;
          _incomingFillTargetIndex = targetIndex;
          _incomingFillProgress = math.min(1.0, (progress - 0.66) / 0.34);
        } else {
          _incomingFillColor = null;
          _incomingFillProgress = null;
          _incomingFillTargetIndex = null;
        }
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          target.fillColor(color, slotIndex: targetSlotIndex);
          _movesRemaining = (_movesRemaining - 1).clamp(0, 999);
          _waveControllers[sourceIndex]
            ..reset()
            ..forward();
          _waveControllers[targetIndex]
            ..reset()
            ..forward();
          _activePour = null;
          _isPouring = false;
          _selectedTubeIndex = null;
          _incomingFillColor = null;
          _incomingFillProgress = null;
          _incomingFillTargetIndex = null;
        });
        controller.dispose();
        if (_movesRemaining == 0) {
          _counterPulseController
            ..reset()
            ..forward();
        }
      }
    });

    setState(() {
      _isPouring = true;
      _activePour?.controller.dispose();
      _activePour = ActivePourState(
        controller: controller,
        color: color,
        sourceIndex: sourceIndex,
        targetIndex: targetIndex,
        start: startCenter,
        end: endCenter,
      );
    });

    controller.forward();
  }

  void _advanceLevel() {
    _currentLevelIndex = (_currentLevelIndex + 1) % glassLevels.length;
    _loadLevel(_currentLevelIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF101010), Color(0xFF181818)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            key: _stackKey,
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final columns = math.min(_tubes.length, 4);
                        final tubeWidth = math.min(96.0, maxWidth / (columns * 1.3));
                        return AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            final shimmerValue = _shimmerController.value;
                            return Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: tubeWidth * 0.35,
                                runSpacing: 36,
                                children: [
                                  for (int i = 0; i < _tubes.length; i++)
                                    GestureDetector(
                                      key: _tubeKeys[i],
                                      onTap: _movesRemaining == 0
                                          ? null
                                          : () => _onTubeTap(i),
                                      child: AnimatedBuilder(
                                        animation: _waveControllers[i],
                                        builder: (context, child) {
                                          return GlassTube(
                                            width: tubeWidth,
                                            height: tubeWidth * 3.6,
                                            shimmerValue: shimmerValue,
                                            tube: _tubes[i],
                                            isSelected: _selectedTubeIndex == i,
                                            waveProgress: _waveControllers[i].value,
                                            incomingFillColor: _incomingFillTargetIndex == i
                                                ? _incomingFillColor
                                                : null,
                                            incomingFillProgress:
                                                _incomingFillTargetIndex == i
                                                    ? (_incomingFillProgress ?? 0)
                                                    : 0,
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: TextButton(
                      onPressed: _advanceLevel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.8),
                      ),
                      child: const Text('Next Level Preview'),
                    ),
                  ),
                ],
              ),
              if (_activePour != null)
                AnimatedBuilder(
                  animation: _activePour!.controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: PourPainter(
                        progress: _activePour!.controller.value,
                        color: _activePour!.color,
                        start: _activePour!.start,
                        end: _activePour!.end,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              if (_movesRemaining == 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${_level.index}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                width: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF40C4FF), Color(0xFFF06292)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _counterPulseController,
            builder: (context, child) {
              final scale = 1 + (_movesRemaining == 0
                      ? (math.sin(_counterPulseController.value * math.pi) * 0.12)
                      : 0)
                  .clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF69F0AE), Color(0xFF40C4FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Moves',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          '$_movesRemaining',
                          key: ValueKey(_movesRemaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ActivePourState {
  ActivePourState({
    required this.controller,
    required this.color,
    required this.start,
    required this.end,
    required this.sourceIndex,
    required this.targetIndex,
  });

  final AnimationController controller;
  final Color color;
  final Offset start;
  final Offset end;
  final int sourceIndex;
  final int targetIndex;
}
