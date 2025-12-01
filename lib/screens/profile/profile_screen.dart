import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user stats when screen opens
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
    final authProvider = context.watch<AuthProvider>();
    final huntProvider = context.watch<HuntProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const GlitchText(
          text: 'PROFILE',
          enableGlitch: false,
        ),
      ),
      body: RefreshIndicator(
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
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: UnseenTheme.bloodRed,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: UnseenTheme.shadowGray,
                child: Text(
                  (user?.displayName ?? 'U')[0].toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: UnseenTheme.bloodRed,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user?.displayName ?? 'Unknown Hunter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                  ),
            ),

            const SizedBox(height: 32),

            // Stats cards
            huntProvider.isLoadingStats
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: UnseenTheme.bloodRed,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.search,
                          value: '${huntProvider.userStats?['huntsCompleted'] ?? 0}',
                          label: 'Hunts\nCompleted',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.stars,
                          value: _formatNumber(huntProvider.userStats?['totalPoints'] ?? 0),
                          label: 'Total\nPoints',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.emoji_events,
                          value: '${huntProvider.completedHunts.length}',
                          label: 'Completed\nHunts',
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 32),

            // Menu items
            _MenuItem(
              icon: Icons.history,
              title: 'Hunt History',
              subtitle: 'View your past hunts',
              onTap: () {
                context.push('/hunt-select/history');
              },
            ),

            _MenuItem(
              icon: Icons.photo_library,
              title: 'Photo Gallery',
              subtitle: 'Your captured moments',
              onTap: () {
                context.push('/photo-gallery');
              },
            ),

            _MenuItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences',
              onTap: () {
                context.push('/settings');
              },
            ),

            const SizedBox(height: 24),

            // Sign out button
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const GlitchText(text: 'SIGN OUT?'),
                    content: const Text(
                      'The darkness will await your return...',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('SIGN OUT'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    context.go(RouteNames.login);
                  }
                }
              },
              icon: const Icon(Icons.logout, color: UnseenTheme.bloodRed),
              label: const Text(
                'SIGN OUT',
                style: TextStyle(color: UnseenTheme.bloodRed),
              ),
            ),

            const SizedBox(height: 16),

            // Delete account
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const GlitchText(text: 'DELETE ACCOUNT?'),
                    content: const Text(
                      'This action cannot be undone. Your soul will be lost forever...',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('KEEP ACCOUNT'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const GlitchText(text: 'FINAL WARNING'),
                              content: const Text(
                                'This will permanently delete your account and all progress. This cannot be undone. Are you absolutely certain?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'DELETE FOREVER',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true && context.mounted) {
                            try {
                              await context.read<AuthProvider>().deleteAccount();
                              if (context.mounted) {
                                context.go(RouteNames.login);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete account: $e'),
                                    backgroundColor: UnseenTheme.bloodRed,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          'DELETE',
                          style: TextStyle(
                            color: Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Delete Account',
                style: TextStyle(
                  color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Version
            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.3),
                  ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UnseenTheme.shadowGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: UnseenTheme.shadowGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: UnseenTheme.bloodRed,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
      ),
    );
  }
}
