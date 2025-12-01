import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.displayName ?? 'Hunter';

    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GlitchText(
                          text: userName.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium,
                          enableGlitch: false,
                        ),
                      ],
                    ),
                    // Profile button
                    IconButton(
                      onPressed: () => context.push(RouteNames.profile),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: UnseenTheme.bloodRed,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: UnseenTheme.bloodRed,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Title
                Center(
                  child: GlitchText(
                    text: AppConstants.appName,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    AppConstants.appTagline,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: 2,
                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                        ),
                  ),
                ),

                const SizedBox(height: 40),

                // Main menu options
                _MenuCard(
                  icon: Icons.play_arrow,
                  title: 'START HUNT',
                  subtitle: 'Begin a new scavenger hunt',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(RouteNames.huntSelect);
                  },
                  isLocked: false,
                ),

                const SizedBox(height: 16),

                _MenuCard(
                  icon: Icons.camera_alt,
                  title: 'PHOTO MODE',
                  subtitle: 'Capture the unseen',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(RouteNames.arPhotoMode);
                  },
                  isLocked: false,
                ),

                const SizedBox(height: 16),

                _MenuCard(
                  icon: Icons.emoji_events,
                  title: 'ACHIEVEMENTS',
                  subtitle: 'View your dark accomplishments',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/achievements');
                  },
                  isLocked: false,
                ),

                const SizedBox(height: 40),

                // Logout button
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      final router = GoRouter.of(context);
                      
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const GlitchText(text: 'LEAVING?'),
                          content: const Text(
                            'The darkness will remember you...',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('STAY'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('LEAVE'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await authProvider.signOut();
                        if (!mounted) return;
                        router.go(RouteNames.login);
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('SIGN OUT'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLocked;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isLocked,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isPressed
              ? UnseenTheme.ashGray
              : UnseenTheme.shadowGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isLocked
                ? UnseenTheme.sicklyCream.withValues(alpha: 0.2)
                : UnseenTheme.bloodRed.withValues(alpha: _isPressed ? 0.8 : 0.4),
            width: 1,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isLocked
                    ? UnseenTheme.ashGray
                    : UnseenTheme.bloodRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.isLocked ? Icons.lock : widget.icon,
                color: widget.isLocked
                    ? UnseenTheme.sicklyCream.withValues(alpha: 0.5)
                    : UnseenTheme.bloodRed,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: widget.isLocked
                              ? UnseenTheme.sicklyCream.withValues(alpha: 0.5)
                              : UnseenTheme.boneWhite,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isLocked
                              ? UnseenTheme.sicklyCream.withValues(alpha: 0.3)
                              : UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: widget.isLocked
                  ? UnseenTheme.sicklyCream.withValues(alpha: 0.3)
                  : UnseenTheme.bloodRed,
            ),
          ],
        ),
      ),
    );
  }
}
