import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/services/audio_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final Random _random = Random();
  bool _showTagline = false;
  bool _showWarning = false;
  List<_GlitchLine> _glitchLines = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    // Start background music (13:42 track, loops continuously)
    final audioService = AudioService();
    audioService.playAmbient(loop: true, volume: 0.6); // 60% volume for background

    // Generate random glitch lines
    _generateGlitchLines();

    // Start fade in
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    // Show tagline
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() => _showTagline = true);
      HapticFeedback.mediumImpact();
    }

    // Show warning
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _showWarning = true);
    }

    // Navigate after splash
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _generateGlitchLines() {
    _glitchLines = List.generate(
      5,
      (index) => _GlitchLine(
        top: _random.nextDouble(),
        height: 2 + _random.nextDouble() * 4,
        opacity: 0.1 + _random.nextDouble() * 0.2,
      ),
    );
  }

  void _navigateToNextScreen() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      context.go(RouteNames.home);
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5 * _pulseAnimation.value,
                    colors: [
                      UnseenTheme.deepBlood.withValues(alpha: 0.3),
                      UnseenTheme.voidBlack,
                    ],
                  ),
                ),
              );
            },
          ),

          // Glitch scan lines
          ...(_glitchLines.map((line) => Positioned(
                top: MediaQuery.of(context).size.height * line.top,
                left: 0,
                right: 0,
                child: Container(
                  height: line.height,
                  color: UnseenTheme.bloodRed.withValues(alpha: line.opacity),
                ),
              ))),

          // Noise overlay
          Opacity(
            opacity: 0.03,
            child: Image.network(
              'https://www.transparenttextures.com/patterns/noise.png',
              repeat: ImageRepeat.repeat,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: GlitchText(
                      text: AppConstants.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 72,
                            shadows: [
                              Shadow(
                                color:
                                    UnseenTheme.bloodRed.withValues(alpha: 0.8),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tagline
                  AnimatedOpacity(
                    opacity: _showTagline ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      AppConstants.appTagline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: UnseenTheme.sicklyCream,
                            letterSpacing: 3,
                          ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Warning text
                  AnimatedOpacity(
                    opacity: _showWarning ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'ENTER AT YOUR OWN RISK',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: UnseenTheme.bloodRed,
                              letterSpacing: 4,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Loading indicator
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      backgroundColor:
                          UnseenTheme.shadowGray.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        UnseenTheme.bloodRed.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Version text
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'v${AppConstants.appVersion}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: UnseenTheme.sicklyCream.withValues(alpha: 0.3),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlitchLine {
  final double top;
  final double height;
  final double opacity;

  _GlitchLine({
    required this.top,
    required this.height,
    required this.opacity,
  });
}
