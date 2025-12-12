import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class ARPhotoModeScreen extends StatefulWidget {
  const ARPhotoModeScreen({super.key});

  @override
  State<ARPhotoModeScreen> createState() => _ARPhotoModeScreenState();
}

class _ARPhotoModeScreenState extends State<ARPhotoModeScreen> {
  CameraController? _cameraController;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showStickers = false;
  int? _selectedStickerIndex;
  Offset _stickerPosition = const Offset(0.5, 0.5);
  double _stickerScale = 1.0;
  double _stickerRotation = 0.0;
  bool _photoTaken = false;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String? _cameraError;

  // Sample stickers
  final List<_StickerData> _stickers = [
    _StickerData(icon: Icons.remove_red_eye, label: 'Eye'),
    _StickerData(icon: Icons.warning, label: 'Warning'),
    _StickerData(icon: Icons.blur_on, label: 'Blur'),
    _StickerData(icon: Icons.local_fire_department, label: 'Fire'),
    _StickerData(icon: Icons.pest_control, label: 'Bug'),
    _StickerData(icon: Icons.psychology, label: 'Mind'),
    _StickerData(icon: Icons.nights_stay, label: 'Moon'),
    _StickerData(icon: Icons.flash_on, label: 'Flash'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkStoragePermission();
  }

  Future<void> _checkStoragePermission() async {
    // Request storage permission on app start
    final status = await _requestStoragePermission();
    if (!status.isGranted) {
      debugPrint('Storage permission not granted: $status');
    }
  }

  Future<PermissionStatus> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use photos permission
      // For Android 10-12 (API 29-32), WRITE_EXTERNAL_STORAGE is ignored but we still need to request it
      // For Android 9 and below, use WRITE_EXTERNAL_STORAGE
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+: Request photos permission
        return await Permission.photos.request();
      } else {
        // Android 12 and below: Request storage permission
        return await Permission.storage.request();
      }
    }
    return PermissionStatus.granted; // iOS or other platforms
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No cameras available';
          _isCameraInitialized = false;
        });
        return;
      }

      // Use back camera if available, otherwise use first camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera error: $e';
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_isCapturing || !_isCameraInitialized || _cameraController == null) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _photoTaken = true;
    });

    HapticFeedback.heavyImpact();

    try {
      // Flash effect
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _photoTaken = false);

      // Capture photo with screenshot (includes stickers overlay)
      final imageBytes = await _captureCompositedImage(context);
      
      if (!mounted) return;
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture image. Please try again.'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
        return;
      }

      if (mounted) {
        // Check storage permission before saving
        final permissionStatus = await _requestStoragePermission();

        if (!permissionStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission denied. Cannot save photo.'),
                backgroundColor: UnseenTheme.bloodRed,
                action: SnackBarAction(
                  label: 'SETTINGS',
                  textColor: UnseenTheme.toxicGreen,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }

        try {
          // Save to gallery
          final saved = await _saveImageToGallery(imageBytes);

          debugPrint('Image saved result: $saved');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check, color: UnseenTheme.toxicGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        saved
                            ? 'Photo saved to gallery'
                            : 'Photo captured (check gallery)',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _sharePhoto(imageBytes),
                      child: const Text('SHARE'),
                    ),
                  ],
                ),
                backgroundColor: UnseenTheme.shadowGray,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: UnseenTheme.bloodRed),
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error saving image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save photo: $e'),
                backgroundColor: UnseenTheme.bloodRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _sharePhoto(Uint8List imageBytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/unseen_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Captured from Unseen - You will wish you hadn\'t seen',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share photo: $e'),
            backgroundColor: UnseenTheme.bloodRed,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _captureCompositedImage(BuildContext context) async {
    try {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final screenshotBytes = await _screenshotController.capture(
        pixelRatio: devicePixelRatio,
        delay: const Duration(milliseconds: 20),
      );
      if (screenshotBytes != null) return screenshotBytes;
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }

    // Fallback to camera capture if screenshot fails (will miss overlays)
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final file = await _cameraController!.takePicture();
        return await file.readAsBytes();
      } catch (e) {
        debugPrint('Error taking fallback picture: $e');
      }
    }
    return null;
  }

  Future<bool> _saveImageToGallery(Uint8List imageBytes) async {
    try {
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: 'unseen_${DateTime.now().millisecondsSinceEpoch}',
      );
      return result != null &&
          (result['isSuccess'] == true ||
              (result['filePath'] != null && result['filePath'] != ''));
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              UnseenTheme.shadowGray,
              UnseenTheme.voidBlack,
              UnseenTheme.shadowGray.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_cameraError != null) ...[
                Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _cameraError!,
                  style: TextStyle(
                    color: UnseenTheme.bloodRed,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const CircularProgressIndicator(
                  color: UnseenTheme.bloodRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing camera...',
                  style: TextStyle(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // For portrait phone camera view, fill the screen and let CameraPreview handle orientation
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),

            // Placed sticker
            if (_selectedStickerIndex != null)
              Positioned(
                left: screenSize.width * _stickerPosition.dx - 40,
                top: screenSize.height * _stickerPosition.dy - 40,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!mounted) return;
                    setState(() {
                      _stickerPosition = Offset(
                        (_stickerPosition.dx +
                                details.delta.dx / screenSize.width)
                            .clamp(0.1, 0.9),
                        (_stickerPosition.dy +
                                details.delta.dy / screenSize.height)
                            .clamp(0.1, 0.9),
                      );
                    });
                  },
                  onScaleUpdate: (details) {
                    if (!mounted) return;
                    setState(() {
                      _stickerScale =
                          (_stickerScale * details.scale).clamp(0.5, 3.0);
                      _stickerRotation += details.rotation;
                    });
                  },
                  child: Transform.rotate(
                    angle: _stickerRotation,
                    child: Transform.scale(
                      scale: _stickerScale,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _stickers[_selectedStickerIndex!].icon,
                          color: UnseenTheme.bloodRed,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Flash effect
            if (_photoTaken)
              Container(
                color: Colors.white,
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: UnseenTheme.boneWhite,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const GlitchText(
                        text: 'CAPTURE THE UNSEEN',
                        enableGlitch: true,
                        glitchInterval: Duration(seconds: 5),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sticker picker
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _showStickers ? 120 : 0,
                      child: _showStickers
                          ? Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: UnseenTheme.shadowGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: UnseenTheme.bloodRed
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HORROR STICKERS',
                                    style: TextStyle(
                                      color: UnseenTheme.sicklyCream
                                          .withValues(alpha: 0.7),
                                      fontSize: 10,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _stickers.length,
                                      itemBuilder: (context, index) {
                                        final sticker = _stickers[index];
                                        final isSelected =
                                            _selectedStickerIndex == index;
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            if (!mounted) return;
                                            setState(() {
                                              _selectedStickerIndex =
                                                  isSelected ? null : index;
                                              if (!isSelected) {
                                                _stickerPosition =
                                                    const Offset(0.5, 0.5);
                                                _stickerScale = 1.0;
                                                _stickerRotation = 0.0;
                                              }
                                            });
                                          },
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            margin: const EdgeInsets.only(
                                                right: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? UnseenTheme.bloodRed
                                                      .withValues(alpha: 0.3)
                                                  : UnseenTheme.ashGray,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? UnseenTheme.bloodRed
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  sticker.icon,
                                                  color: isSelected
                                                      ? UnseenTheme.bloodRed
                                                      : UnseenTheme.sicklyCream,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 2),
                                                Flexible(
                                                  child: Text(
                                                    sticker.label,
                                                    style: TextStyle(
                                                      fontSize: 7,
                                                      color: UnseenTheme
                                                          .sicklyCream
                                                          .withValues(alpha: 0.7),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 16),

                    // Control buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Stickers button
                          _ControlButton(
                            icon: Icons.emoji_emotions,
                            label: 'Stickers',
                            isActive: _showStickers,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showStickers = !_showStickers);
                            },
                          ),

                          // Capture button
                          GestureDetector(
                            onTap: _isCapturing ? null : _takePhoto,
                            child: Opacity(
                              opacity: _isCapturing ? 0.5 : 1.0,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: UnseenTheme.bloodRed,
                                    width: 4,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: UnseenTheme.bloodRed,
                                  ),
                                  child: _isCapturing
                                      ? const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(
                                            color: UnseenTheme.boneWhite,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),

                          // Gallery button
                          _ControlButton(
                            icon: Icons.photo_library,
                            label: 'Gallery',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.push('/photo-gallery');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerData {
  final IconData icon;
  final String label;

  _StickerData({required this.icon, required this.label});
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? UnseenTheme.bloodRed.withValues(alpha: 0.3)
                  : UnseenTheme.shadowGray,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? UnseenTheme.bloodRed
                    : UnseenTheme.sicklyCream.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? UnseenTheme.bloodRed : UnseenTheme.sicklyCream,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
