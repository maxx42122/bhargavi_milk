import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/animated_fluid_waves.dart';
import '../../widgets/bvh_logo_widget.dart';
import '../auth/login_screen.dart';
import '../distributor/distributor_dashboard_screen.dart';
import '../shop/shop_home_screen.dart';

/// Attractive, high-performance animated splash screen for MilkRoute / BVH.
class AnimatedSplashScreen extends StatefulWidget {
  /// If true, runs as a stand-alone preview without auto-navigating away.
  final bool isPreviewMode;

  const AnimatedSplashScreen({
    super.key,
    this.isPreviewMode = false,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _waveController;
  late final AnimationController _particleController;
  late final AnimationController _floatingController;

  // Staggered animation stages
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _shimmerProgress;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progressOpacity;
  late final Animation<double> _floatingOffset;

  // State
  bool _isNavigating = false;
  ({UserRole role, String distributorId, String status})? _resolvedRole;
  User? _currentUser;

  @override
  void initState() {
    super.initState();

    // 1. Coordinated Master Entrance Timeline (2200ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 2. Ambient Continuous Loops
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 3. Staggered Entrance Animations
    _backdropOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );

    _shimmerProgress = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.20, 0.85, curve: Curves.easeInOut),
    );

    _textOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _progressOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
    );

    _floatingOffset = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOutSine),
    );

    // Start timeline
    _mainController.forward();

    if (!widget.isPreviewMode) {
      _startAppInitialization();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // INITIALIZATION & AUTH RESOLUTION
  // ---------------------------------------------------------------------------

  Future<void> _startAppInitialization() async {
    // 1. Minimum splash display duration for smooth animation experience
    final timerFuture = Future.delayed(const Duration(milliseconds: 2300));

    // 2. Concurrently resolve Firebase Auth & Role
    final authFuture = _resolveAuth();

    await Future.wait([timerFuture, authFuture]);

    if (mounted && !_isNavigating) {
      _proceedToTargetScreen();
    }
  }

  Future<void> _resolveAuth() async {
    try {
      final user = AuthService.currentUser;
      _currentUser = user;

      if (user != null && !AuthService.isRegistering) {
        _resolvedRole = await AuthService.resolveCurrentUserRole();
      }
    } catch (_) {
      // In case of network/offline or resolve error, will safely fallback to LoginScreen
      _currentUser = null;
    }
  }

  void _proceedToTargetScreen() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;

    final authState = AuthStateScope.of(context);
    final user = _currentUser;
    final resolved = _resolvedRole;

    Widget target;

    if (user == null || resolved == null) {
      authState.clear();
      target = const LoginScreen();
    } else {
      authState.setResolved(
        role: resolved.role,
        distributorId: resolved.distributorId,
        status: resolved.status,
      );

      if (resolved.role == UserRole.distributor) {
        target = const DistributorDashboardScreen();
      } else if (resolved.status == 'active') {
        target = ShopHomeScreen(distributorId: resolved.distributorId);
      } else {
        target = _ShopPendingFallbackScreen(status: resolved.status);
      }
    }

    // Smooth luxury fade-through route transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => target,
        transitionDuration: const Duration(milliseconds: 650),
        transitionsBuilder: (context, anim, secAnim, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final locale = LocaleScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0C2B4E),
      body: Stack(
        children: [
          // 1. Dynamic Luxury Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF09223D), // Deep midnight navy
                    Color(0xFF0F3D66), // Rich royal blue
                    Color(0xFF1660A6), // Milk blue deep
                    Color(0xFF1B7BD6), // Vibrant milk blue
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // 2. Giant Faded Background Logo Watermark (Slow Ambient Hover)
          Positioned.fill(
            child: FadeTransition(
              opacity: _backdropOpacity,
              child: Center(
                child: AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, _) {
                    final offset = _floatingOffset.value;
                    return Transform.translate(
                      offset: Offset(0, offset * 1.8),
                      child: Transform.scale(
                        scale: 1.02 + (offset / 100.0),
                        child: Opacity(
                          opacity: 0.13, // Soft luminous watermark
                          child: Image.asset(
                            'assets/images/logo_v_3d.png',
                            width: size.width * 0.88,
                            height: size.width * 0.88,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (ctx, err, stack) => const SizedBox(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. Ambient Floating Glowing Droplets / Bokeh
          Positioned.fill(
            child: FadeTransition(
              opacity: _backdropOpacity,
              child: AmbientGlowParticles(
                animation: _particleController,
                count: 16,
              ),
            ),
          ),

          // 4. Central Ambient Radial Glow behind the Logo
          Positioned(
            top: size.height * 0.20,
            left: size.width * 0.05,
            right: size.width * 0.05,
            child: FadeTransition(
              opacity: _backdropOpacity,
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        const Color(0xFF3B94E8).withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Multi-layered Continuous Fluid Waves at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedFluidWaves(
              animation: _waveController,
              height: size.height * 0.26,
            ),
          ),

          // 6. Main Center Content: Prominent Visible Logo + Brand + Typography
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Prominent Animated Logo Card with Spring Entrance & Hovering
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingOffset.value),
                            child: child,
                          );
                        },
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: BvhLogoWidget(
                              size: 140,
                              shimmerAnimation: _shimmerProgress,
                              showCard: true,
                              useFullLogo: false,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Brand Name & Tagline with Staggered Slide-Fade
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            children: [
                              // "BVH" Primary Title & Badge
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'BVH',
                                    style: GoogleFonts.figtree(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 18,
                                          offset: const Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                      ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF00E5FF)
                                            .withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: GoogleFonts.figtree(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: const Color(0xFFE2F9FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // "Better Vendor Hub" Subheading
                              Text(
                                'Better Vendor Hub',
                                style: GoogleFonts.figtree(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFFE0F2FE),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Dairy / Milk Tagline
                              Text(
                                locale.t('login_tagline'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.figtree(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFB0D2F4),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Animated Loading Pill Progress Indicator
                      FadeTransition(
                        opacity: _progressOpacity,
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: AnimatedBuilder(
                                  animation: _waveController,
                                  builder: (context, _) {
                                    final t = _waveController.value;
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.4 + 0.6 * _mathSinProgress(t),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF00E5FF),
                                              Color(0xFF70B8F8),
                                              Colors.white,
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              locale.t('loading'),
                              style: GoogleFonts.figtree(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 6. Bottom App Version & Trademark
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: FadeTransition(
              opacity: _progressOpacity,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Text(
                    'MilkRoute • Powered by Better Vendor Hub',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: AppColors.ink900.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 7. Preview Mode Replay Button (Only in Preview Mode)
          if (widget.isPreviewMode)
            Positioned(
              top: 48,
              right: 20,
              child: IconButton.filledTonal(
                onPressed: () {
                  _mainController.reset();
                  _mainController.forward();
                },
                icon: const Icon(Icons.replay_rounded),
                tooltip: 'Replay Animation',
              ),
            ),
        ],
      ),
    );
  }

  double _mathSinProgress(double t) {
    return (1 + (t * 2 - 1).abs()) / 2;
  }
}

// Fallback Shop Pending Screen in case invoked during splash transition
class _ShopPendingFallbackScreen extends StatelessWidget {
  final String status;

  const _ShopPendingFallbackScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: rejected
                        ? AppColors.red100
                        : AppColors.amber100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                    size: 40,
                    color: rejected
                        ? AppColors.red600
                        : AppColors.amber600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  rejected ? 'Registration Rejected' : 'Awaiting Approval',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 10),
                Text(
                  rejected
                      ? 'Your registration was not approved by the distributor. Please contact them directly.'
                      : 'Your registration request has been sent to the distributor. You will be able to log in once they approve your account.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.innerRadius),
                      ),
                    ),
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
