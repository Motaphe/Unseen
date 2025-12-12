import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/services/audio_service.dart';
import 'package:unseen/services/haptic_service.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _audioEnabled = true;
  bool _hapticsEnabled = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load settings from shared preferences or defaults
    // For now, using defaults
    setState(() {
      _audioEnabled = true;
      _hapticsEnabled = true;
      _notificationsEnabled = true;
    });
  }

  void _saveSettings() {
    // Save settings to shared preferences
    // For now, just update the services
    final audioService = AudioService();
    audioService.setEnabled(_audioEnabled);
    if (!_audioEnabled) {
      audioService.stopAmbient();
      audioService.stopLoopingSfx();
    }
    // Haptics will be disabled in the service if needed
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
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
          text: 'SETTINGS',
          enableGlitch: false,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            Text(
              'ACCOUNT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: UnseenTheme.bloodRed,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: UnseenTheme.shadowGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: UnseenTheme.bloodRed),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Preferences Section
            Text(
              'PREFERENCES',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: UnseenTheme.bloodRed,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 16),

            _SettingTile(
              icon: Icons.volume_up,
              title: 'Audio',
              subtitle: 'Enable sound effects and music',
              value: _audioEnabled,
              onChanged: (value) {
                setState(() => _audioEnabled = value);
                _saveSettings();
              },
            ),

            _SettingTile(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              subtitle: 'Enable vibration effects',
              value: _hapticsEnabled,
              onChanged: (value) {
                setState(() => _hapticsEnabled = value);
                _saveSettings();
              },
            ),

            _SettingTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Enable push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
            ),

            const SizedBox(height: 32),

            // About Section
            Text(
              'ABOUT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: UnseenTheme.bloodRed,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: UnseenTheme.shadowGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UnseenTheme.shadowGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: UnseenTheme.bloodRed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticService().lightImpact();
              onChanged(newValue);
            },
            activeThumbColor: UnseenTheme.bloodRed,
            activeTrackColor: UnseenTheme.bloodRed.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
