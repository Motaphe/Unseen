import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final huntProvider = context.read<HuntProvider>();
      final userId = authProvider.user?.uid;
      if (userId != null) {
        huntProvider.loadUserStats(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final huntProvider = context.watch<HuntProvider>();
    final stats = huntProvider.userStats;
    final completedHunts = huntProvider.completedHunts;

    final achievements = _calculateAchievements(
      huntsCompleted: stats?['huntsCompleted'] ?? 0,
      totalPoints: stats?['totalPoints'] ?? 0,
      completedHuntsCount: completedHunts.length,
    );

    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const GlitchText(
          text: 'ACHIEVEMENTS',
          enableGlitch: false,
        ),
      ),
      body: huntProvider.isLoadingStats
          ? const Center(
              child: CircularProgressIndicator(
                color: UnseenTheme.bloodRed,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final authProvider = context.read<AuthProvider>();
                final huntProvider = context.read<HuntProvider>();
                final userId = authProvider.user?.uid;
                if (userId != null) {
                  await huntProvider.loadUserStats(userId);
                }
              },
              color: UnseenTheme.bloodRed,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: UnseenTheme.shadowGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Icons.emoji_events,
                              value: '${achievements.where((a) => a['unlocked'] == true).length}',
                              label: 'Unlocked',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.lock,
                              value: '${achievements.where((a) => a['unlocked'] == false).length}',
                              label: 'Locked',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Achievements List
                    Text(
                      'YOUR ACHIEVEMENTS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: UnseenTheme.bloodRed,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: 16),

                    ...achievements.map((achievement) => _AchievementCard(
                          title: achievement['title'] as String,
                          description: achievement['description'] as String,
                          icon: achievement['icon'] as IconData,
                          unlocked: achievement['unlocked'] as bool,
                          progress: achievement['progress'] as double?,
                        )),
                  ],
                ),
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _calculateAchievements({
    required int huntsCompleted,
    required int totalPoints,
    required int completedHuntsCount,
  }) {
    return [
      {
        'title': 'First Steps',
        'description': 'Complete your first hunt',
        'icon': Icons.directions_walk,
        'unlocked': huntsCompleted >= 1,
        'progress': huntsCompleted >= 1 ? 1.0 : (huntsCompleted / 1).clamp(0.0, 1.0),
      },
      {
        'title': 'Hunter',
        'description': 'Complete 3 hunts',
        'icon': Icons.search,
        'unlocked': huntsCompleted >= 3,
        'progress': huntsCompleted >= 3 ? 1.0 : (huntsCompleted / 3).clamp(0.0, 1.0),
      },
      {
        'title': 'Master Hunter',
        'description': 'Complete 10 hunts',
        'icon': Icons.verified,
        'unlocked': huntsCompleted >= 10,
        'progress': huntsCompleted >= 10 ? 1.0 : (huntsCompleted / 10).clamp(0.0, 1.0),
      },
      {
        'title': 'Point Collector',
        'description': 'Earn 1000 points',
        'icon': Icons.stars,
        'unlocked': totalPoints >= 1000,
        'progress': totalPoints >= 1000 ? 1.0 : (totalPoints / 1000).clamp(0.0, 1.0),
      },
      {
        'title': 'Point Master',
        'description': 'Earn 5000 points',
        'icon': Icons.workspace_premium,
        'unlocked': totalPoints >= 5000,
        'progress': totalPoints >= 5000 ? 1.0 : (totalPoints / 5000).clamp(0.0, 1.0),
      },
      {
        'title': 'Nightmare Seeker',
        'description': 'Complete a nightmare difficulty hunt',
        'icon': Icons.warning,
        'unlocked': completedHuntsCount > 0, // Simplified - would check difficulty
        'progress': completedHuntsCount > 0 ? 1.0 : 0.0,
      },
    ];
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: UnseenTheme.bloodRed,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: UnseenTheme.boneWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final double? progress;

  const _AchievementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? UnseenTheme.shadowGray
            : UnseenTheme.shadowGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? UnseenTheme.bloodRed.withValues(alpha: 0.5)
              : UnseenTheme.sicklyCream.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unlocked
                  ? UnseenTheme.bloodRed.withValues(alpha: 0.2)
                  : UnseenTheme.ashGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              unlocked ? icon : Icons.lock,
              color: unlocked ? UnseenTheme.bloodRed : UnseenTheme.sicklyCream.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: unlocked
                            ? UnseenTheme.boneWhite
                            : UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                      ),
                ),
                if (progress != null && !unlocked && progress! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: UnseenTheme.ashGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(UnseenTheme.bloodRed),
                    ),
                  ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(
              Icons.check_circle,
              color: UnseenTheme.toxicGreen,
            ),
        ],
      ),
    );
  }
}
