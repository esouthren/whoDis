import 'package:flutter/material.dart';

class CountdownScreen extends StatefulWidget {
  final String title;
  final VoidCallback onComplete;

  const CountdownScreen({
    super.key,
    required this.title,
    required this.onComplete,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int? _currentCount;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    for (int i = 3; i >= 1; i--) {
      if (mounted) {
        setState(() {
          _currentCount = i;
        });
        _controller.reset();
        _controller.forward();
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
              SizedBox(
                height: 140,
                child: _currentCount != null
                    ? FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          '$_currentCount',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
