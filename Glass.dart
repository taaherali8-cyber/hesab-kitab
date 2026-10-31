import 'dart:ui';
import 'package:flutter/material.dart';

/// پس‌زمینه‌ی شیشه‌ای (الهام از لیکویید گلس)
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0B0E14), Color(0xFF141B2E), Color(0xFF0B0E14)],
              ),
            ),
          ),
        ),
        Positioned(top: -80, left: -60, child: _blob(const Color(0xFF7C4DFF), 190)),
        Positioned(top: 140, right: -90, child: _blob(const Color(0xFF00BFA5), 160)),
        Positioned(bottom: -110, left: 50, child: _blob(const Color(0xFFFF6E9C), 190)),
      ],
    );
  }

  Widget _blob(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: c.withOpacity(.32), blurRadius: 90, spreadRadius: 40),
          ],
        ),
      );
}

/// کارت شیشه‌ای با بلور واقعی (BackdropFilter)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.14),
                Colors.white.withOpacity(.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.18)),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}