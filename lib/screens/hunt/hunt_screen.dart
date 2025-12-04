import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/widgets/common/creepy_button.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/services/haptic_service.dart';
import 'package:unseen/services/audio_service.dart';
import 'package:unseen/widgets/horror/horror_overlay.dart';

class HuntScreen extends StatefulWidget {
  final String huntId;

  const HuntScreen({super.key, required this.huntId});

  @override
  State<HuntScreen> createState() => _HuntScreenState();
}

class _HuntScreenState extends State<HuntScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showHint = false;
  bool _isLoading = true;
  bool _hasPromptedCompleted = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    // Load hunt data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHunt();
    });
  }

  Future<void> _loadHunt() async {
    final authProvider = context.read<AuthProvider>();
    final huntProvider = context.read<HuntProvider>();
    final user = authProvider.user;

    if (user == null) {
      // User not logged in, redirect to login
      if (mounted) {
        context.go(RouteNames.login);
      }
      return;
    }

    setState(() => _isLoading = true);
    _hasPromptedCompleted = false;

    try {
      await huntProvider.startHunt(widget.huntId, user.uid);

      // Check if hunt loaded successfully (either from Firestore or local)
      if (huntProvider.isHuntLoaded) {
        if (huntProvider.isHuntCompleted && !_hasPromptedCompleted) {
          _hasPromptedCompleted = true;
          _showCompletedActionSheet();
        } else {
          // Add ambient whispers for atmosphere (looping)
          if (mounted) {
            final audioService = AudioService();
            audioService.playWhispers(loop: true); // Eerie whispers during hunt
          }
        }
      } else if (huntProvider.hasError) {
        // Error state - will be shown in the error UI
        debugPrint('⚠️ Hunt failed to load: ${huntProvider.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Exception in _loadHunt: $e');
      // Don't show snackbar here - let the error UI handle it
      // The huntProvider state will have the error message
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (!huntProvider.isHuntCompleted) {
          _startElapsedTimer();
        }
      }
    }
  }

  @override
  void dispose() {
    // Stop ambient whispers when leaving hunt screen
    final audioService = AudioService();
    audioService.stopWhispers();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _timer?.cancel();
    final huntProvider = context.read<HuntProvider>();
    final startedAt = huntProvider.currentProgress?.startedAt;
    if (startedAt == null) return;
    _elapsed = DateTime.now().difference(startedAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = huntProvider.currentProgress?.startedAt;
      if (current == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(current);
      });
    });
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  void _openARView() {
    final huntProvider = context.read<HuntProvider>();
    final currentClue = huntProvider.currentClue;

    if (currentClue == null) {
      return;
    }

    HapticService().mediumImpact();
    context.push(
      '${RouteNames.arView}/${widget.huntId}/${currentClue.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final huntProvider = context.watch<HuntProvider>();
    final clues = huntProvider.currentClues;
    final progress = huntProvider.progressPercentage;
    
    // Get current clue based on stored progress
    final currentClue = huntProvider.currentClue;

    // If a completed run slipped through to build (e.g. navigation race), prompt options
    if (huntProvider.isHuntCompleted &&
        !_hasPromptedCompleted &&
        !_isLoading &&
        mounted) {
      _hasPromptedCompleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletedActionSheet();
      });
    }

    if (_isLoading || huntProvider.isLoading) {
      return Scaffold(
        backgroundColor: UnseenTheme.voidBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: UnseenTheme.bloodRed,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading the hunt...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen only if:
    // 1. There's an actual error AND no hunt/clues loaded, OR
    // 2. Hunt/clues failed to load completely
    // Don't show error if hunt and clues are loaded but currentClue is null (progress issue)
    final hasHuntData = huntProvider.currentHunt != null && clues.isNotEmpty;
    final shouldShowError = huntProvider.hasError && !hasHuntData;
    
    if (shouldShowError || (!hasHuntData && huntProvider.isLoading == false)) {
      final errorMessage = huntProvider.errorMessage ?? 'Failed to load hunt';
      final isConnectionError = errorMessage.contains('Google Play Services') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('Connection') ||
          errorMessage.contains('Firebase');
      
      return Scaffold(
        backgroundColor: UnseenTheme.voidBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(RouteNames.home),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: UnseenTheme.bloodRed,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  isConnectionError 
                      ? 'Connection lost...'
                      : 'The hunt has been corrupted...',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isConnectionError
                      ? 'Unable to connect to the server. The app will use offline mode if available.'
                      : errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                if (huntProvider.isUsingLocalData) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UnseenTheme.toxicGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: UnseenTheme.toxicGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.offline_bolt,
                          color: UnseenTheme.toxicGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Using offline mode',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: UnseenTheme.toxicGreen,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadHunt(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UnseenTheme.bloodRed,
                    foregroundColor: UnseenTheme.boneWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text('RETURN HOME'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ensure we have a valid clue before rendering
    if (currentClue == null) {
      return Scaffold(
        backgroundColor: UnseenTheme.voidBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: UnseenTheme.bloodRed,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No clue available. Please retry or replay.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadHunt,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final currentClueIndex = huntProvider.currentProgress?.currentClueOrder ?? 0;

    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        title: Text(
          'CLUE ${currentClueIndex + 1}/${clues.length}',
          style: const TextStyle(letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => _showHint = !_showHint),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: UnseenTheme.shadowGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        UnseenTheme.bloodRed,
                      ),
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Progress text
                  Text(
                    '${huntProvider.currentProgress?.cluesFoundCount ?? 0} of ${clues.length} clues found  •  Elapsed ${_formatElapsed(_elapsed)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Clue card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: UnseenTheme.shadowGray,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: UnseenTheme.bloodRed.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Clue icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search,
                            color: UnseenTheme.bloodRed,
                            size: 40,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Hint text
                        GlitchText(
                          text: currentClue.hint,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                          enableGlitch: true,
                          glitchInterval: const Duration(seconds: 5),
                        ),

                        // Location hint
                        if ((currentClue.locationHint ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  color: UnseenTheme.toxicGreen,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentClue.locationHint!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.85),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // QR Code preview
                        if (currentClue.qrCode != null && currentClue.qrCode!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: UnseenTheme.voidBlack.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.qr_code_2,
                                        color: UnseenTheme.bloodRed,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TARGET QR CODE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: UnseenTheme.bloodRed,
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: UnseenTheme.boneWhite,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: QrImageView(
                                      data: currentClue.qrCode!,
                                      version: QrVersions.auto,
                                      size: 120,
                                      backgroundColor: UnseenTheme.boneWhite,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: UnseenTheme.voidBlack,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: UnseenTheme.voidBlack,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scan this code to find the clue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Additional hint
                        AnimatedCrossFade(
                          firstChild: const SizedBox(height: 0),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: UnseenTheme.ashGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: UnseenTheme.decayYellow,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      currentClue.fullHint,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: UnseenTheme.sicklyCream,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          crossFadeState: _showHint
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Open AR button
                  CreepyButton(
                    text: 'SCAN FOR CLUE',
                    onPressed: _openARView,
                    icon: Icons.camera,
                  ),
                ],
              ),
            ),
          ),
          const HorrorOverlay(intensity: 0.25),
        ],
      ),
    );
  }

  Future<void> _showCompletedActionSheet() async {
    if (!mounted) return;
    final huntProvider = context.read<HuntProvider>();
    final huntName = huntProvider.currentHunt?.name ?? 'this hunt';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: UnseenTheme.shadowGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$huntName is already completed.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: UnseenTheme.boneWhite,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can revisit your results or replay without earning extra points.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: () {
                  Navigator.pop(context);
                  context.go('${RouteNames.huntComplete}/${widget.huntId}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: UnseenTheme.bloodRed,
                  foregroundColor: UnseenTheme.boneWhite,
                ),
                label: const Text('VIEW RESULTS'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.replay),
                onPressed: () async {
                  Navigator.pop(context);
                  await _handleReplay();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: UnseenTheme.boneWhite,
                  side: const BorderSide(color: UnseenTheme.bloodRed),
                ),
                label: const Text('REPLAY (NO NEW POINTS)'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(RouteNames.home);
                },
                child: const Text('BACK TO HOME'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleReplay() async {
    final authProvider = context.read<AuthProvider>();
    final huntProvider = context.read<HuntProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (mounted) {
        context.go(RouteNames.login);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await huntProvider.restartHunt(widget.huntId, user.uid);

      // Resume ambience for the fresh run
      final audioService = AudioService();
      audioService.playWhispers(loop: true);

      if (mounted) {
        _hasPromptedCompleted = false;
        _startElapsedTimer();
      }
    } catch (e) {
      debugPrint('❌ Replay failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to restart hunt: $e'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const GlitchText(text: 'ABANDON HUNT?'),
        content: const Text(
          'Your progress will be lost in the darkness...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE HUNT'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteNames.home);
            },
            child: const Text('ABANDON'),
          ),
        ],
      ),
    );
  }
}
