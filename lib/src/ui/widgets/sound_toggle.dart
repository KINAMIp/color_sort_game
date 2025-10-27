import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class GradientSoundToggle extends StatelessWidget {
  const GradientSoundToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final appState = Provider.maybeOf<AppState>(context, listen: false);
        appState?.audioService.playButtonTap();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: value
                ? const [Color(0xFF7CF6F3), Color(0xFF7288FF)]
                : const [Color(0xFFFF9A9E), Color(0xFFFFB347)],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    value ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: value ? const Color(0xFF7288FF) : const Color(0xFFFF9A9E),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value ? 'Sound On' : 'Sound Off',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
