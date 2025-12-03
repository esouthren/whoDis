import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _StyledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? side;

  const _StyledButton({
    required this.onPressed,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    this.side,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      textStyle: GoogleFonts.bungee(fontSize: 18),
    );

   

    final buttonChild = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(text),
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: buttonChild,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StyledButton(
      onPressed: onPressed,
      text: text,
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor:
          Color.lerp(theme.colorScheme.tertiary, Colors.white, 0.2)!,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StyledButton(
      onPressed: onPressed,
      text: text,
      backgroundColor: theme.colorScheme.tertiary,
      foregroundColor:
          Color.lerp(theme.colorScheme.primary, Colors.black, 0.2)!,
      side: BorderSide(color: theme.colorScheme.tertiary, width: 2),
    );
  }
}
