import 'package:flutter/material.dart';

/// A reusable full-screen loading overlay with a mystical message.
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Dim background
        Positioned.fill(
          child: Container(color: scheme.onPrimaryContainer),
        ),
        // Centered card with spinner and message
        Center(
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.titleLarge,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
