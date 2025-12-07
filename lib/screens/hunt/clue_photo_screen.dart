import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/providers/auth_provider.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/services/audio_service.dart';
import 'package:unseen/services/haptic_service.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class CluePhotoScreen extends StatefulWidget {
  final String huntId;
  final String clueId;

  const CluePhotoScreen({
    super.key,
    required this.huntId,
    required this.clueId,
  });

  @override
  State<CluePhotoScreen> createState() => _CluePhotoScreenState();
}

class _CluePhotoScreenState extends State<CluePhotoScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isUploading = false;
  String? _errorMessage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device';
          _isCameraReady = false;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera failed to start: $e';
        _isCameraReady = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidence() async {
    if (!_isCameraReady || _cameraController == null || _isCapturing || _isUploading) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be signed in to record evidence.'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
        context.go(RouteNames.login);
      }
      return;
    }

    try {
      final huntProvider = context.read<HuntProvider>();
      setState(() {
        _isCapturing = true;
      });
      HapticService().heavyImpact();
      AudioService().playHeartbeat(loop: false);

      final picture = await _cameraController!.takePicture();
      final file = File(picture.path);

      setState(() {
        _isUploading = true;
      });

      // Save to device gallery
      final result = await ImageGallerySaver.saveFile(
        picture.path,
        name: 'unseen_${widget.huntId}_${widget.clueId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      String? photoUrl;

      // Try to upload to Firebase Storage (optional - won't fail if storage not configured)
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
              '${AppConstants.userPhotosPath}/${user.uid}/${widget.huntId}_${widget.clueId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

        await storageRef.putFile(file);
        photoUrl = await storageRef.getDownloadURL();
      } catch (storageError) {
        // Firebase Storage not configured or failed - continue with local save only
        debugPrint('⚠️ Firebase Storage upload failed (continuing anyway): $storageError');
        photoUrl = picture.path; // Use local path as fallback
      }

      await huntProvider.markClueFound(
        widget.clueId,
        user.uid,
        photoUrl: photoUrl,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evidence saved to gallery!'),
          backgroundColor: UnseenTheme.toxicGreen.withValues(alpha: 0.9),
          duration: const Duration(seconds: 2),
        ),
      );

      context.go('${RouteNames.clueFound}/${widget.huntId}/${widget.clueId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture evidence: $e'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: Stack(
        children: [
          _buildCameraView(),
          _buildOverlay(),
          _buildTopBar(),
          _buildBottomCard(),
          if (_isUploading) _buildUploadingShield(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: UnseenTheme.bloodRed),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: UnseenTheme.bloodRed),
      );
    }

    return CameraPreview(_cameraController!);
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            UnseenTheme.voidBlack.withValues(alpha: 0.4),
            Colors.transparent,
            UnseenTheme.voidBlack.withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = 1 + (_pulseController.value * 0.05);
            return Transform.scale(
              scale: pulse,
              child: Container(
                width: 260,
                height: 360,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isUploading
                        ? UnseenTheme.toxicGreen
                        : UnseenTheme.bloodRed.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _roundIcon(
                icon: Icons.close,
                onTap: () => context.pop(),
              ),
              const Spacer(),
              _roundIcon(
                icon: Icons.camera,
                onTap: () {},
                isActive: _isCameraReady,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    final huntProvider = context.watch<HuntProvider>();
    final clue = huntProvider.currentClues.isNotEmpty
        ? huntProvider.currentClues.firstWhere(
            (c) => c.id == widget.clueId,
            orElse: () => huntProvider.currentClues.first,
          )
        : huntProvider.currentClue;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: UnseenTheme.voidBlack.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UnseenTheme.bloodRed.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: UnseenTheme.bloodRed.withValues(alpha: 0.15),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlitchText(
                  text: 'CAPTURE THE PROOF',
                  enableGlitch: true,
                  glitchInterval: const Duration(seconds: 3),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: UnseenTheme.boneWhite,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  clue?.locationHint != null && clue!.locationHint!.isNotEmpty
                      ? clue.locationHint!
                      : 'Frame the object, then capture. Evidence is required to proceed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UnseenTheme.sicklyCream.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: (_isCapturing || _isUploading) ? null : _captureEvidence,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: UnseenTheme.boneWhite,
                          ),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(
                    _isUploading ? 'UPLOADING EVIDENCE...' : 'CAPTURE EVIDENCE',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UnseenTheme.bloodRed,
                    foregroundColor: UnseenTheme.boneWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingShield() {
    return Container(
      color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: UnseenTheme.bloodRed),
            SizedBox(height: 12),
            Text(
              'Sealing the evidence...',
              style: TextStyle(color: UnseenTheme.boneWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
          border: Border.all(
            color: isActive
                ? UnseenTheme.toxicGreen.withValues(alpha: 0.7)
                : UnseenTheme.bloodRed.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? UnseenTheme.toxicGreen : UnseenTheme.boneWhite,
        ),
      ),
    );
  }
}
