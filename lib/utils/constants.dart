class AppConstants {
  // App Info
  static const String appName = 'UNSEEN';
  static const String appTagline = 'You will wish you hadn\'t seen';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String huntsCollection = 'hunts';
  static const String cluesCollection = 'clues';
  static const String progressCollection = 'progress';

  // Storage Paths
  static const String modelsPath = 'models';
  static const String stickersPath = 'stickers';
  static const String userPhotosPath = 'user_photos';

  // Animation Durations
  static const Duration splashDuration = Duration(milliseconds: 3000);
  static const Duration fadeInDuration = Duration(milliseconds: 800);
  static const Duration glitchDuration = Duration(milliseconds: 150);
  static const Duration typingDuration = Duration(milliseconds: 50);

  // AR Settings
  static const double defaultModelScale = 0.5;
  static const double minModelScale = 0.1;
  static const double maxModelScale = 2.0;
  static const double interactionDistance = 2.0; // meters

  // Gameplay
  static const int maxHintsPerClue = 3;
  static const int pointsPerClue = 100;
  static const int bonusTimeLimit = 300; // seconds for bonus points

  // Horror Effects
  static const double glitchIntensity = 0.3;
  static const double flickerFrequency = 0.1;
  static const int maxJumpScareInterval = 120; // seconds
}

class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String huntSelect = '/hunt-select';
  static const String hunt = '/hunt';
  static const String arView = '/ar-view';
  static const String arPhotoMode = '/ar-photo-mode';
  static const String cluePhoto = '/clue-photo';
  static const String clueFound = '/clue-found';
  static const String huntComplete = '/hunt-complete';
  static const String profile = '/profile';
  static const String adminHuntBuilder = '/admin/hunt-builder';
  static const String adminQrSheet = '/admin/qr-sheet';
}

class AssetPaths {
  // Images
  static const String imagesPath = 'assets/images/';
  static const String stickersPath = 'assets/images/stickers/';
  static const String logo = 'assets/images/logo.png';
  static const String splashBg = 'assets/images/splash_bg.png';

  // Models
  static const String modelsPath = 'assets/models/';

  // Audio
  static const String audioPath = 'assets/audio/';
  static const String ambientBackground = 'assets/audio/background.mp3'; // Main background (13:42)
  static const String whispers = 'assets/audio/whispers.mp3';
  static const String jumpScare = 'assets/audio/jump_scare.mp3';
  static const String heartbeat = 'assets/audio/heartbeat.mp3';
  static const String footsteps = 'assets/audio/footsteps.mp3';
  static const String clueFound = 'assets/audio/clue_found.mp3';
}
