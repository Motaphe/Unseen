import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/models/user_progress.dart';
import 'package:unseen/services/firestore_service.dart';
import 'package:unseen/models/hunt.dart';
import 'package:intl/intl.dart';

class HuntHistoryScreen extends StatefulWidget {
  const HuntHistoryScreen({super.key});

  @override
  State<HuntHistoryScreen> createState() => _HuntHistoryScreenState();
}

class _HuntHistoryScreenState extends State<HuntHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final completedProgress = await _firestoreService.getCompletedHunts(userId);
      final items = <Map<String, dynamic>>[];

      for (final progress in completedProgress) {
        final hunt = await _firestoreService.getHunt(progress.huntId);
        if (hunt != null) {
          items.add({
            'hunt': hunt,
            'progress': progress,
          });
        }
      }

      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return 'N/A';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const GlitchText(
          text: 'HUNT HISTORY',
          enableGlitch: false,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: UnseenTheme.bloodRed,
              ),
            )
          : _errorMessage != null
              ? Center(
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
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                    )
                  : _historyItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                color: UnseenTheme.sicklyCream.withValues(alpha: 0.3),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No completed hunts yet...',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete your first hunt to see it here',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: UnseenTheme.sicklyCream.withValues(alpha: 0.3),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: UnseenTheme.bloodRed,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _historyItems.length,
                            itemBuilder: (context, index) {
                              final item = _historyItems[index];
                              final hunt = item['hunt'] as Hunt;
                              final progress = item['progress'] as UserProgress;

                              return _HistoryCard(
                                hunt: hunt,
                                progress: progress,
                                formatDuration: _formatDuration,
                              );
                            },
                          ),
                        ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Hunt hunt;
  final UserProgress progress;
  final String Function(int?) formatDuration;

  const _HistoryCard({
    required this.hunt,
    required this.progress,
    required this.formatDuration,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'nightmare':
        return UnseenTheme.bloodRed;
      case 'hard':
        return Colors.orange;
      case 'medium':
        return UnseenTheme.decayYellow;
      case 'easy':
        return UnseenTheme.toxicGreen;
      default:
        return UnseenTheme.sicklyCream;
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(hunt.difficulty);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final completedDate = progress.completedAt != null
        ? dateFormat.format(progress.completedAt!)
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: UnseenTheme.shadowGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hunt.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: UnseenTheme.boneWhite,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: difficultyColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    hunt.difficulty,
                    style: TextStyle(
                      color: difficultyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: completedDate,
                ),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.timer,
                  label: 'Time',
                  value: formatDuration(progress.timeTakenSeconds),
                ),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.stars,
                  label: 'Points',
                  value: '${progress.pointsEarned ?? 0}',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Clues found
            Text(
              '${progress.cluesFoundCount}/${hunt.clueCount} clues found',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: UnseenTheme.bloodRed,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: UnseenTheme.boneWhite,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
