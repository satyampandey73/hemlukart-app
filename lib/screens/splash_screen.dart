import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  // Staggered Animations
  late Animation<double> _backgroundFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _sloganFade;
  late Animation<double> _sloganSlide;
  late Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Define staggered animations using Intervals
    _backgroundFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeIn),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    _sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    _sloganSlide = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Navigate to next screen after delay
    Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final double scaleVal = 0.95 + (0.05 * animation.value);
              return FadeTransition(
                opacity: animation,
                child: Transform.scale(
                  scale: scaleVal,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  Color(0xFF04352D),
                  Color(0xFF021B17),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. Ambient Glow Effects
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _backgroundFade.value,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.25),
                          AppColors.secondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _backgroundFade.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.18),
                          AppColors.secondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Animated Logo + Pulse Rings
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, childWidget) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse ring
                                  Container(
                                    width: 140 + (_pulseController.value * 50),
                                    height: 140 + (_pulseController.value * 50),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25 * (1.0 - _pulseController.value)),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Inner pulse ring
                                  Container(
                                    width: 140 + (((_pulseController.value + 0.5) % 1.0) * 50),
                                    height: 140 + (((_pulseController.value + 0.5) % 1.0) * 50),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15 * (1.0 - ((_pulseController.value + 0.5) % 1.0))),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  childWidget!,
                                ],
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/banner.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Animated App Name
                      Opacity(
                        opacity: _titleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _titleSlide.value),
                          child: const Text(
                            'Hemlukart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Animated Tagline
                      Opacity(
                        opacity: _sloganFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _sloganSlide.value),
                          child: Text(
                            'Care at your fingertips',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Animated Loading indicator
                      Opacity(
                        opacity: _loaderFade.value,
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ThreeDotLoading(),
                              SizedBox(height: 12),
                              Text(
                                'Loading your experience...',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDotLoading extends StatefulWidget {
  const _ThreeDotLoading();

  @override
  State<_ThreeDotLoading> createState() => _ThreeDotLoadingState();
}

class _ThreeDotLoadingState extends State<_ThreeDotLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Smooth sine wave calculation for offset
            final double offset = (index * pi / 3.0);
            final double verticalShift = sin(_controller.value * 2 * pi - offset) * 6.0;
            final double intensity = (verticalShift + 6.0) / 12.0;

            return Transform.translate(
              offset: Offset(0, verticalShift),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3 + 0.7 * intensity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2 * intensity),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
