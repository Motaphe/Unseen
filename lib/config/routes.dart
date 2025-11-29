import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unseen/screens/splash_screen.dart';
import 'package:unseen/screens/auth/login_screen.dart';
import 'package:unseen/screens/auth/register_screen.dart';
import 'package:unseen/screens/home/home_screen.dart';
import 'package:unseen/screens/home/hunt_select_screen.dart';
import 'package:unseen/screens/hunt/hunt_screen.dart';
import 'package:unseen/screens/hunt/clue_found_screen.dart';
import 'package:unseen/screens/hunt/hunt_complete_screen.dart';
import 'package:unseen/screens/hunt/clue_photo_screen.dart';
import 'package:unseen/screens/admin/hunt_builder_screen.dart';
import 'package:unseen/screens/admin/qr_sheet_screen.dart';
import 'package:unseen/screens/ar/ar_view_screen.dart';
import 'package:unseen/screens/ar/ar_photo_mode_screen.dart';
import 'package:unseen/screens/profile/profile_screen.dart';
import 'package:unseen/screens/profile/hunt_history_screen.dart';
import 'package:unseen/screens/profile/photo_gallery_screen.dart';
import 'package:unseen/screens/profile/settings_screen.dart';
import 'package:unseen/screens/home/achievements_screen.dart';
import 'package:unseen/utils/constants.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPageWithFade(
          context,
          state,
          const SplashScreen(),
        ),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const RegisterScreen(),
        ),
      ),

      // Main App Routes
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithFade(
          context,
          state,
          const HomeScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.huntSelect,
        name: 'huntSelect',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const HuntSelectScreen(),
        ),
        routes: [
          GoRoute(
            path: 'history',
            name: 'huntHistory',
            pageBuilder: (context, state) => _buildPageWithSlide(
              context,
              state,
              const HuntHistoryScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '${RouteNames.hunt}/:huntId',
        name: 'hunt',
        pageBuilder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          return _buildPageWithFade(
            context,
            state,
            HuntScreen(huntId: huntId),
          );
        },
      ),

      // AR Routes
      GoRoute(
        path: '${RouteNames.arView}/:huntId/:clueId',
        name: 'arView',
        pageBuilder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          final clueId = state.pathParameters['clueId']!;
          return _buildPageWithFade(
            context,
            state,
            ARViewScreen(huntId: huntId, clueId: clueId),
          );
        },
      ),
      GoRoute(
        path: RouteNames.arPhotoMode,
        name: 'arPhotoMode',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const ARPhotoModeScreen(),
        ),
      ),
      GoRoute(
        path: '${RouteNames.cluePhoto}/:huntId/:clueId',
        name: 'cluePhoto',
        pageBuilder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          final clueId = state.pathParameters['clueId']!;
          return _buildPageWithFade(
            context,
            state,
            CluePhotoScreen(huntId: huntId, clueId: clueId),
          );
        },
      ),

      // Hunt Progress Routes
      GoRoute(
        path: '${RouteNames.clueFound}/:huntId/:clueId',
        name: 'clueFound',
        pageBuilder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          final clueId = state.pathParameters['clueId']!;
          return _buildPageWithGlitch(
            context,
            state,
            ClueFoundScreen(huntId: huntId, clueId: clueId),
          );
        },
      ),
      GoRoute(
        path: '${RouteNames.huntComplete}/:huntId',
        name: 'huntComplete',
        pageBuilder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          return _buildPageWithFade(
            context,
            state,
            HuntCompleteScreen(huntId: huntId),
          );
        },
      ),
      GoRoute(
        path: RouteNames.adminHuntBuilder,
        name: 'adminHuntBuilder',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const HuntBuilderScreen(),
        ),
      ),
      GoRoute(
        path: '${RouteNames.adminQrSheet}/:huntId',
        name: 'adminQrSheet',
        pageBuilder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          return _buildPageWithFade(
            context,
            state,
            QrSheetScreen(huntId: huntId),
          );
        },
      ),

      // Profile
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/photo-gallery',
        name: 'photoGallery',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const PhotoGalleryScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        pageBuilder: (context, state) => _buildPageWithSlide(
          context,
          state,
          const AchievementsScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF8B0000),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'SOMETHING WENT WRONG',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The path you seek does not exist...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('RETURN'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Page Transitions
  static CustomTransitionPage _buildPageWithFade(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage _buildPageWithSlide(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  static CustomTransitionPage _buildPageWithGlitch(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Glitch-like transition with multiple fades
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final value = animation.value;
            // Create a glitchy opacity effect
            double opacity = value;
            if (value > 0.2 && value < 0.3) opacity = 0.5;
            if (value > 0.5 && value < 0.6) opacity = 0.3;
            if (value > 0.7 && value < 0.75) opacity = 0.8;

            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: child,
            );
          },
        );
      },
    );
  }
}
