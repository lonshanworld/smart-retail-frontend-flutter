import 'dart:ui';

import 'package:flutter/material.dart';

class PublicPremiumShell extends StatelessWidget {
  const PublicPremiumShell({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF5F8FC),
  });

  final Widget child;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: baseColor,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor,
                  const Color(0xFFEAF1F9),
                  const Color(0xFFF7FBFF),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: IgnorePointer(child: _PremiumAuras())),
        child,
      ],
    );
  }
}

class _PremiumAuras extends StatefulWidget {
  const _PremiumAuras();

  @override
  State<_PremiumAuras> createState() => _PremiumAurasState();
}

class _PremiumAurasState extends State<_PremiumAuras>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          children: [
            _AuraBlob(
              alignment: Alignment(-0.95 + (t * 0.25), -0.9 + (t * 0.12)),
              color: const Color(0x3323A6D5),
              size: 360,
            ),
            _AuraBlob(
              alignment: Alignment(0.95 - (t * 0.3), -0.5 + (t * 0.2)),
              color: const Color(0x2A0EA5A4),
              size: 300,
            ),
            _AuraBlob(
              alignment: Alignment(-0.2 + (t * 0.25), 0.95 - (t * 0.2)),
              color: const Color(0x22FF9F1C),
              size: 420,
            ),
          ],
        );
      },
    );
  }
}

class _AuraBlob extends StatelessWidget {
  const _AuraBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
