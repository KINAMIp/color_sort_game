import 'package:flutter/material.dart';

class FilledActionButton extends StatelessWidget {
  const FilledActionButton({
    super.key,
    required this.label,
    required this.colors,
    required this.onPressed,
    this.textColor = Colors.white,
    this.uppercase = true,
    this.verticalPadding = 18,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onPressed;
  final Color textColor;
  final bool uppercase;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final displayLabel = uppercase ? label.toUpperCase() : label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55231A25),
                blurRadius: 18,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Text(
            displayLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
