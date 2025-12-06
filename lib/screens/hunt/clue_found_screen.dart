import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/widgets/common/creepy_button.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/models/clue.dart';
import 'package:unseen/services/firestore_service.dart';
import 'package:unseen/services/audio_service.dart';
import 'package:unseen/services/haptic_service.dart';

class ClueFoundScreen extends StatefulWidget {
  final String huntId;
  final String clueId;

  const ClueFoundScreen({
    super.key,
    required this.huntId,
    required this.clueId,
  });

  @override
  State<ClueFoundScreen> createState() => _ClueFoundScreenState();
}

class _ClueFoundScreenState extends State<ClueFoundScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _showNarrative = false;
  String _displayedNarrative = '';
  int _narrativeIndex = 0;
  Timer? _typingTimer;
  String _narrative = 'Loading...';
  String? _photoUrl;
  bool _isLastClue = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadClueData();
  }

  Future<void> _loadClueData() async {
    final huntProvider = context.read<HuntProvider>();
    final progress = huntProvider.currentProgress;
    Clue? clue;

    // Prefer already-loaded clue data (works offline)
    try {
      clue = huntProvider.currentClues
          .firstWhere((c) => c.id == widget.clueId);
    } catch (_) {
      clue = null;
    }

    try {
      // Fallback to Firestore if the clue is not in memory
      clue ??= await FirestoreService().getClue(widget.clueId);

      if (!mounted) return;

      if (clue != null) {
        final resolvedClue = clue;
        setState(() {
          _narrative = resolvedClue.narrative;
          _photoUrl = progress?.evidencePhotos[widget.clueId];
        });

        final clues = huntProvider.currentClues;
        if (clues.isNotEmpty) {
          // Find the clue with the highest order number
          final maxOrder = clues.map((c) => c.order).reduce((a, b) => a > b ? a : b);
          _isLastClue = resolvedClue.order >= maxOrder;
        } else {
          // Fallback: check if this is clue_5 (for "The Forgotten Ritual")
          _isLastClue = widget.clueId == 'clue_5';
        }

        _startReveal();
      } else {
        setState(() {
          _narrative = 'You found something... but wish you hadn\'t.';
        });
        _startReveal();
      }
    } catch (e) {
      setState(() {
        _narrative = 'You found something... but wish you hadn\'t.';
      });
      _startReveal();
    }
  }

  void _startReveal() async {
    final hapticService = HapticService();
    final audioService = AudioService();
    
    // Play clue found sound and vibration
    hapticService.clueFoundVibration();
    audioService.playClueFound();

    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _showNarrative = true);
      _startTypingNarrative();
    }
  }

  void _startTypingNarrative() {
    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 40),
      (timer) {
        if (_narrativeIndex < _narrative.length) {
          setState(() {
            _displayedNarrative = _narrative.substring(0, _narrativeIndex + 1);
            _narrativeIndex++;
          });

          // Add haptic on certain characters
          if (_narrative[_narrativeIndex - 1] == '.' ||
              _narrative[_narrativeIndex - 1] == '!') {
            HapticService().lightImpact();
          }
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _continue() {
    // Check if this was the last clue
    if (_isLastClue) {
      context.go('${RouteNames.huntComplete}/${widget.huntId}');
    } else {
      // Go back to hunt screen
      context.go('${RouteNames.hunt}/${widget.huntId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: Stack(
        children: [
          // Pulsing background
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2 * _pulseAnimation.value,
                    colors: [
                      UnseenTheme.bloodRed.withValues(alpha: 0.3),
                      UnseenTheme.voidBlack,
                    ],
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Found icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                              border: Border.all(
                                color: UnseenTheme.bloodRed,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      UnseenTheme.bloodRed.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: UnseenTheme.bloodRed,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Title
                    GlitchText(
                      text: 'CLUE FOUND',
                      style: Theme.of(context).textTheme.displaySmall,
                      enableGlitch: true,
                      glitchInterval: const Duration(seconds: 3),
                    ),

                    const SizedBox(height: 24),

                    if (_photoUrl != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UnseenTheme.voidBlack.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: UnseenTheme.bloodRed.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _photoUrl!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: _photoUrl!,
                                  placeholder: (context, url) => const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: UnseenTheme.bloodRed,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    height: 200,
                                    color: UnseenTheme.shadowGray,
                                    child: const Center(
                                      child: Icon(
                                        Icons.photo_camera,
                                        color: UnseenTheme.bloodRed,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  color: UnseenTheme.shadowGray,
                                  child: const Center(
                                    child: Icon(
                                      Icons.photo_camera,
                                      color: UnseenTheme.bloodRed,
                                      size: 48,
                                    ),
                                  ),
                                ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Narrative text
                    AnimatedOpacity(
                      opacity: _showNarrative ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: UnseenTheme.shadowGray.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _displayedNarrative,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.8,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Continue button
                    AnimatedOpacity(
                      opacity:
                          _narrativeIndex >= _narrative.length ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 300),
                      child: CreepyButton(
                        text: _isLastClue ? 'COMPLETE HUNT' : 'CONTINUE',
                        onPressed: _narrativeIndex >= _narrative.length
                            ? _continue
                            : null,
                        icon: Icons.arrow_forward,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
