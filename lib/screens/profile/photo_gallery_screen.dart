import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/utils/constants.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> with WidgetsBindingObserver {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndLoadPhotos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground, recheck permissions
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      _checkPermissionAndLoadPhotos();
    }
  }

  Future<void> _checkPermissionAndLoadPhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check current permission state without requesting
      // Try to access photos to see if we have permission
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );
      
      // If we can get albums, we have permission
      if (albums.isNotEmpty) {
        debugPrint('Permission granted - found ${albums.length} albums');
        setState(() => _hasPermission = true);
        await _loadPhotos();
        return;
      }

      // If no albums, check permission state explicitly
      final PermissionState currentPermission = await PhotoManager.requestPermissionExtend();
      
      debugPrint('Current photo permission state: ${currentPermission.name}');
      
      if (currentPermission.isAuth || currentPermission == PermissionState.limited) {
        // Permission granted or limited (iOS 14+)
        setState(() => _hasPermission = true);
        await _loadPhotos();
      } else {
        // Permission not granted
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Permission required to view photos.';
        });
      }
    } catch (e) {
      debugPrint('Error checking photo permission: $e');
      // If error is permission-related, try requesting
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        // Try requesting permission
        await _requestPermissionAndLoadPhotos();
      } else {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Error checking permissions: $e';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissionAndLoadPhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request permission (this will show system dialog if needed)
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      
      debugPrint('Photo permission state after request: ${permission.name}');
      
      if (permission.isAuth || permission == PermissionState.limited) {
        // Permission granted or limited (iOS 14+)
        setState(() => _hasPermission = true);
        await _loadPhotos();
      } else {
        // Permission denied
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Permission denied. Please grant photo access in device settings.';
        });
      }
    } catch (e) {
      debugPrint('Error requesting photo permission: $e');
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Error requesting permissions: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPhotos() async {
    try {
      // Get all photos
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      if (albums.isEmpty) {
        setState(() => _photos = []);
        return;
      }

      // Get photos from the first album (usually "Recent" or "All Photos")
      final AssetPathEntity recentAlbum = albums.first;
      final List<AssetEntity> allPhotos = await recentAlbum.getAssetListRange(
        start: 0,
        end: 200, // Load up to 200 photos for better performance
      );

      // Show recent photos immediately (sorted by date)
      allPhotos.sort((a, b) {
        return b.createDateTime.compareTo(a.createDateTime);
      });
      
      // Set photos immediately for display
      setState(() {
        _photos = allPhotos;
      });

      // Then filter for unseen photos in background (optional optimization)
      // For now, just show all recent photos since filtering is slow
      debugPrint('Loaded ${allPhotos.length} photos from gallery');
    } catch (e) {
      debugPrint('Error loading photos: $e');
      setState(() {
        _errorMessage = 'Error loading photos: $e';
        _photos = [];
      });
    }
  }

  Future<void> _showPhotoDetail(AssetEntity photo) async {
    if (!mounted) return;
    final file = await photo.file;
    if (file == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: UnseenTheme.boneWhite,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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
          text: 'PHOTO GALLERY',
          enableGlitch: false,
        ),
        actions: [
          if (_hasPermission)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPhotos,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: UnseenTheme.bloodRed,
              ),
            )
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : _photos.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadPhotos,
                      color: UnseenTheme.bloodRed,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          return _PhotoThumbnail(
                            asset: _photos[index],
                            onTap: () => _showPhotoDetail(_photos[index]),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Permission Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: UnseenTheme.boneWhite,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ??
                  'We need access to your photos to show your captured images.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await _requestPermissionAndLoadPhotos();
                // Also try to open settings if permission still denied
                if (!_hasPermission) {
                  // On Android, we can try to open app settings
                  // This is handled by the permission system dialog
                  debugPrint('Permission still not granted after request');
                }
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('GRANT PERMISSION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UnseenTheme.bloodRed,
                foregroundColor: UnseenTheme.boneWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Refresh permission check
                await _checkPermissionAndLoadPhotos();
              },
              child: Text(
                'REFRESH',
                style: TextStyle(
                  color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Photos Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: UnseenTheme.boneWhite,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Capture photos in Photo Mode to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.arPhotoMode),
              icon: const Icon(Icons.camera_alt),
              label: const Text('OPEN PHOTO MODE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UnseenTheme.bloodRed,
                foregroundColor: UnseenTheme.boneWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.asset,
    required this.onTap,
  });

  @override
  State<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<_PhotoThumbnail> {
  Uint8List? _thumbnailBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final thumbnail = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );
      if (mounted) {
        setState(() {
          _thumbnailBytes = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: UnseenTheme.bloodRed.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _isLoading
              ? Container(
                  color: UnseenTheme.shadowGray,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: UnseenTheme.bloodRed,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _thumbnailBytes == null
                  ? Container(
                      color: UnseenTheme.shadowGray,
                      child: const Icon(
                        Icons.broken_image,
                        color: UnseenTheme.bloodRed,
                      ),
                    )
                  : Image.memory(
                      _thumbnailBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: UnseenTheme.shadowGray,
                        child: const Icon(
                          Icons.broken_image,
                          color: UnseenTheme.bloodRed,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
