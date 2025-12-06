import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/widgets/common/creepy_button.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/services/haptic_service.dart';
import 'package:unseen/services/audio_service.dart';

class HuntCompleteScreen extends StatefulWidget {
  final String huntId;

  const HuntCompleteScreen({super.key, required this.huntId});

  @override
  State<HuntCompleteScreen> createState() => _HuntCompleteScreenState();
}

class _HuntCompleteScreenState extends State<HuntCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnimation;

  bool _showStats = false;
  bool _showButton = false;
  final Random _random = Random();

  // Stats (loaded from Firestore)
  int _cluesFound = 0;
  int _totalClues = 0;
  Duration _timeTaken = Duration.zero;
  int _pointsEarned = 0;
  List<_EvidenceTile> _evidence = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _loadCompletionData();
  }

  Future<void> _loadCompletionData() async {
    final huntProvider = context.read<HuntProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      _startCelebration();
      return;
    }

    try {
      // Calculate time taken
      final progress = huntProvider.currentProgress;
      if (progress != null && progress.startedAt != null) {
        final endTime = progress.completedAt ?? DateTime.now();
        _timeTaken = endTime.difference(progress.startedAt!);
      }

      // Get stats from progress
      _cluesFound = huntProvider.currentProgress?.cluesFoundCount ?? 0;
      _totalClues = huntProvider.currentClues.length;
      _pointsEarned = huntProvider.currentProgress?.pointsEarned ?? 0;
      _evidence = _buildEvidence(huntProvider);

      // If hunt not completed yet, complete it now
      if (progress != null && !progress.isCompleted) {
        await huntProvider.completeHunt(
          userId: user.uid,
          timeTakenSeconds: _timeTaken.inSeconds,
        );
        // Reload to get updated points
        _pointsEarned = huntProvider.currentProgress?.pointsEarned ?? 0;
      }
    } catch (e) {
      // Use defaults if error
      _cluesFound = huntProvider.currentClues.length;
      _totalClues = huntProvider.currentClues.length;
      _evidence = [];
    } finally {
      _startCelebration();
    }
  }

  List<_EvidenceTile> _buildEvidence(HuntProvider huntProvider) {
    final progress = huntProvider.currentProgress;
    if (progress == null || progress.evidencePhotos.isEmpty) return [];
    final orderMap = {
      for (final clue in huntProvider.currentClues) clue.id: clue.order,
    };
    final hintMap = {
      for (final clue in huntProvider.currentClues) clue.id: clue.hint,
    };
    final entries = progress.evidencePhotos.entries.toList()
      ..sort((a, b) {
        final ao = orderMap[a.key] ?? 0;
        final bo = orderMap[b.key] ?? 0;
        return ao.compareTo(bo);
      });
    return entries
        .map(
          (e) => _EvidenceTile(
            clueLabel: 'Clue ${orderMap[e.key] ?? '?'}',
            hint: hintMap[e.key] ?? '',
            url: e.value,
          ),
        )
        .toList();
  }

  void _startCelebration() async {
    final hapticService = HapticService();
    final audioService = AudioService();
    
    hapticService.heavyImpact();
    audioService.playClueFound(); // Celebration sound

    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    hapticService.mediumImpact();
    if (mounted) setState(() => _showStats = true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _showButton = true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _shareAchievement() async {
    HapticFeedback.lightImpact();
    
    try {
      final huntProvider = context.read<HuntProvider>();
      final hunt = huntProvider.currentHunt;
      
      final shareText = '''
🎯 Hunt Complete: ${hunt?.name ?? 'Unknown Hunt'}

📊 Stats:
• Clues Found: $_cluesFound/$_totalClues
• Time Taken: ${_formatDuration(_timeTaken)}
• Points Earned: $_pointsEarned

${AppConstants.appTagline}
#UnseenAR
''';

      await Share.share(
        shareText,
        subject: 'I completed a hunt in ${AppConstants.appName}!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: Stack(
        children: [
          // Particle effect background
          ...List.generate(20, (index) {
            return AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                final progress = (_celebrationController.value + index / 20) % 1;
                return Positioned(
                  left: _random.nextDouble() * MediaQuery.of(context).size.width,
                  top: MediaQuery.of(context).size.height * (1 - progress),
                  child: Opacity(
                    opacity: (1 - progress) * 0.5,
                    child: Icon(
                      Icons.star,
                      color: UnseenTheme.bloodRed,
                      size: 8 + _random.nextDouble() * 8,
                    ),
                  ),
                );
              },
            );
          }),

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

                    // Trophy icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            UnseenTheme.bloodRed.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: UnseenTheme.bloodRed,
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    GlitchText(
                      text: 'HUNT COMPLETE',
                      style: Theme.of(context).textTheme.displaySmall,
                      enableGlitch: true,
                      glitchInterval: const Duration(seconds: 4),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'You survived... this time.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                          ),
                    ),

                    const SizedBox(height: 48),

                    // Stats
                    Flexible(
                      child: AnimatedOpacity(
                        opacity: _showStats ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: SingleChildScrollView(
                          child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: UnseenTheme.shadowGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _StatRow(
                              icon: Icons.search,
                              label: 'Clues Found',
                              value: '$_cluesFound / $_totalClues',
                            ),
                            const Divider(height: 24),
                            _StatRow(
                              icon: Icons.timer,
                              label: 'Time Taken',
                              value: _formatDuration(_timeTaken),
                            ),
                            const Divider(height: 24),
                          _StatRow(
                            icon: Icons.stars,
                            label: 'Points Earned',
                            value: '+$_pointsEarned',
                            valueColor: UnseenTheme.toxicGreen,
                          ),
                          if (_evidence.isNotEmpty) ...[
                            const Divider(height: 28),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Evidence Captured',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: UnseenTheme.sicklyCream),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _evidence.length,
                                separatorBuilder: (_, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final item = _evidence[index];
                                  return _EvidenceCard(item: item);
                                },
                              ),
                            ),
                          ],
                        ],
                          ),
                        ),
                      ),
                    ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          CreepyButton(
                            text: 'SHARE ACHIEVEMENT',
                            onPressed: () => _shareAchievement(),
                            icon: Icons.share,
                            isPrimary: false,
                          ),
                          const SizedBox(height: 16),
                          CreepyButton(
                            text: 'RETURN HOME',
                            onPressed: () => context.go(RouteNames.home),
                            icon: Icons.home,
                          ),
                        ],
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

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: UnseenTheme.bloodRed,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? UnseenTheme.boneWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _EvidenceTile {
  final String clueLabel;
  final String hint;
  final String url;

  _EvidenceTile({
    required this.clueLabel,
    required this.hint,
    required this.url,
  });
}

class _EvidenceCard extends StatelessWidget {
  final _EvidenceTile item;

  const _EvidenceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: UnseenTheme.shadowGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UnseenTheme.bloodRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
              child: item.url.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: item.url,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 90,
                        color: UnseenTheme.voidBlack.withValues(alpha: 0.4),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: UnseenTheme.bloodRed,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 90,
                        color: UnseenTheme.shadowGray,
                        child: const Center(
                          child: Icon(
                            Icons.photo_camera,
                            color: UnseenTheme.bloodRed,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 90,
                      width: double.infinity,
                      color: UnseenTheme.shadowGray,
                      child: const Center(
                        child: Icon(
                          Icons.photo_camera,
                          color: UnseenTheme.bloodRed,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clueLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: UnseenTheme.boneWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: UnseenTheme.sicklyCream.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
