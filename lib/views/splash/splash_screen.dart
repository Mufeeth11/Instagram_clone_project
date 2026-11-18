import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

/// Authentic Instagram-styled Splash Screen.
/// Displays the signature Instagram gradient logo with entrance animation
/// and the "from Meta" branding at the bottom, respecting Dark and Light modes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _footerFadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Smooth spring-like scale for the central Instagram logo
    _scaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // Fade-in for the central logo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Subtle delayed fade for the "from Meta" footer
    _footerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.90, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto-navigate once the splash sequence concludes (2.0 seconds)
    _navigationTimer = Timer(const Duration(milliseconds: 2000), _proceed);
  }

  void _proceed() {
    if (!mounted) return;
    final loggedIn = ref.read(authControllerProvider).isLoggedIn;
    context.go(loggedIn ? '/main' : '/login');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceed, // Allows immediate skipping on tap
        child: Stack(
          children: [
            // Center Instagram Gradient Glyph
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: const _InstagramGlyph(size: 96),
              ),
            ),

            // Bottom "from Meta" Branding
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: FadeTransition(
                opacity: _footerFadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'from',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.6,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF0064E0),
                          Color(0xFF0082FB),
                          Color(0xFFFA383E),
                          Color(0xFFFD8D32),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.all_inclusive,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Meta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pixel-perfect, vector-drawn Instagram app icon glyph
class _InstagramGlyph extends StatelessWidget {
  final double size;

  const _InstagramGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const RadialGradient(
          center: Alignment(-0.8, 1.0),
          radius: 1.4,
          colors: [
            Color(0xFFFFD600), // Yellow
            Color(0xFFFF7A00), // Orange
            Color(0xFFFF0069), // Pink
            Color(0xFFD300C5), // Magenta
            Color(0xFF7638FA), // Purple
          ],
          stops: [0.0, 0.25, 0.55, 0.80, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0069).withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _InstagramCameraPainter(strokeWidth: size * 0.075),
      ),
    );
  }
}

/// Draws the white camera outline, lens, and flash inside the glyph
class _InstagramCameraPainter extends CustomPainter {
  final double strokeWidth;

  const _InstagramCameraPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Rounded rectangle border of the camera
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.62,
        height: size.height * 0.62,
      ),
      Radius.circular(size.width * 0.17),
    );
    canvas.drawRRect(rect, strokePaint);

    // Center circular camera lens
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final lensRadius = size.width * 0.155;
    canvas.drawCircle(center, lensRadius, strokePaint);

    // Flash light dot at top-right
    final dotCenter = Offset(size.width * 0.68, size.height * 0.32);
    final dotRadius = strokeWidth * 0.72;
    canvas.drawCircle(dotCenter, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _InstagramCameraPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}
