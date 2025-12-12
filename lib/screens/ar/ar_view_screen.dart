import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/models/clue.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/services/audio_service.dart';
import 'package:unseen/services/haptic_service.dart';

class ARViewScreen extends StatefulWidget {
  final String huntId;
  final String clueId;

  const ARViewScreen({
    super.key,
    required this.huntId,
    required this.clueId,
  });

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen>
    with TickerProviderStateMixin {
  MobileScannerController? _scannerController;
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late AnimationController _glitchController;

  bool _isScanning = true;
  bool _clueFound = false;
  bool _wrongCodeScanned = false;
  String? _lastScannedCode;
  String? _errorMessage;
  bool _torchEnabled = false;
  bool _virtualQrMode = false; // Toggle for virtual QR code overlay

  bool get _shouldShowVirtualOverlay => _virtualQrMode && _isScanning && !_clueFound;
  bool get _shouldShowPhysicalScanUi => _isScanning && !_virtualQrMode && !_clueFound;
  bool get _physicalScannerActive => !_virtualQrMode && _isScanning && !_clueFound;

  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _initializeScanner();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    _glitchController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_physicalScannerActive) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? scannedValue = barcodes.first.rawValue;
    if (scannedValue == null) return;

    _handleQrValue(scannedValue);
  }

  void _handleQrValue(String scannedValue, {bool fromVirtual = false}) {
    if (_clueFound || scannedValue.isEmpty) return;
    if (!_isScanning && !fromVirtual) return;

    final cleanedValue = scannedValue.trim();
    if (cleanedValue.isEmpty) return;
    if (cleanedValue == _lastScannedCode && !fromVirtual) return;

    _lastScannedCode = cleanedValue;

    // Get the expected QR code for the current clue
    final huntProvider = context.read<HuntProvider>();
    final currentClue = _getCurrentClue(huntProvider);
    final expectedQrCode = currentClue.qrCode;

    // If no QR is configured, treat any scan as success to avoid blocking players
    if (expectedQrCode == null || expectedQrCode.isEmpty) {
      _onCorrectQrScanned();
      return;
    }

    // Check if scanned code matches
    if (cleanedValue == expectedQrCode) {
      _onCorrectQrScanned();
    } else {
      _onWrongQrScanned(cleanedValue);
    }
  }

  void _onCorrectQrScanned() {
    setState(() {
      _isScanning = false;
      _clueFound = true;
      _wrongCodeScanned = false;
    });

    // Haptic feedback and audio
    HapticService().heavyImpact();
    _audioService.playJumpScare();

    // Trigger glitch effect
    _glitchController.forward().then((_) {
      _glitchController.reverse();
    });

    // Navigate to photo capture after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.push(
          '${RouteNames.cluePhoto}/${widget.huntId}/${widget.clueId}',
        );
      }
    });
  }

  void _onWrongQrScanned(String scannedValue) {
    setState(() {
      _wrongCodeScanned = true;
      _errorMessage = 'Wrong location... keep searching';
    });

    HapticService().errorVibration();
    _audioService.playDistantWhisper();

    // Trigger glitch
    _glitchController.forward().then((_) {
      _glitchController.reverse();
    });

    // Reset after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _wrongCodeScanned = false;
          _errorMessage = null;
          _lastScannedCode = null;
        });
      }
    });
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _scannerController?.toggleTorch();
    HapticService().lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      body: Stack(
        children: [
          // QR Scanner
          if (_scannerController != null)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return _buildErrorView(error.errorDetails?.message ?? 'Camera error');
              },
            ),

          // Horror overlay effects
          _buildHorrorOverlay(),

          // Virtual QR Code Overlay (when in virtual mode)
          if (_shouldShowVirtualOverlay) _buildVirtualQrOverlay(),

          // Scanning frame
          if (_shouldShowPhysicalScanUi) _buildScanningFrame(),

          // Scan line animation
          if (_shouldShowPhysicalScanUi) _buildScanLine(),

          // Found overlay
          if (_clueFound) _buildFoundOverlay(),

          // Wrong code overlay
          if (_wrongCodeScanned) _buildWrongCodeOverlay(),

          // Top bar
          _buildTopBar(),

          // Bottom info
          _buildBottomInfo(),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      color: UnseenTheme.voidBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Camera unavailable',
              style: TextStyle(
                color: UnseenTheme.bloodRed,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorrorOverlay() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        final glitchValue = _glitchController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent,
                UnseenTheme.voidBlack.withValues(alpha: 0.3 + (glitchValue * 0.3)),
                UnseenTheme.voidBlack.withValues(alpha: 0.7 + (glitchValue * 0.2)),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: glitchValue > 0.5
              ? Opacity(
                  opacity: 0.3,
                  child: Container(
                    color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildScanningFrame() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = _pulseController.value;
          return Container(
            width: 280 + (pulseValue * 10),
            height: 280 + (pulseValue * 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: _wrongCodeScanned
                    ? UnseenTheme.bloodRed
                    : UnseenTheme.bloodRed.withValues(alpha: 0.5 + (pulseValue * 0.3)),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: UnseenTheme.bloodRed.withValues(alpha: 0.2 + (pulseValue * 0.2)),
                  blurRadius: 20 + (pulseValue * 10),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Corner brackets
                ..._buildCornerBrackets(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const size = 30.0;
    const color = UnseenTheme.bloodRed;

    return [
      // Top left
      Positioned(
        top: 0,
        left: 0,
        child: _CornerBracket(size: size, color: color, corner: _Corner.topLeft),
      ),
      // Top right
      Positioned(
        top: 0,
        right: 0,
        child: _CornerBracket(size: size, color: color, corner: _Corner.topRight),
      ),
      // Bottom left
      Positioned(
        bottom: 0,
        left: 0,
        child: _CornerBracket(size: size, color: color, corner: _Corner.bottomLeft),
      ),
      // Bottom right
      Positioned(
        bottom: 0,
        right: 0,
        child: _CornerBracket(size: size, color: color, corner: _Corner.bottomRight),
      ),
    ];
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final centerY = screenHeight / 2;
        final scanAreaHeight = 280.0;
        final startY = centerY - (scanAreaHeight / 2);
        final lineY = startY + (scanAreaHeight * _scanLineController.value);

        return Positioned(
          top: lineY,
          left: (MediaQuery.of(context).size.width - 280) / 2,
          child: Container(
            width: 280,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  UnseenTheme.bloodRed.withValues(alpha: 0.8),
                  UnseenTheme.bloodRed,
                  UnseenTheme.bloodRed.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoundOverlay() {
    return Container(
      color: UnseenTheme.voidBlack.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                      border: Border.all(
                        color: UnseenTheme.bloodRed,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: UnseenTheme.bloodRed.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: UnseenTheme.toxicGreen,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const GlitchText(
              text: 'FOUND',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              enableGlitch: true,
              glitchInterval: Duration(milliseconds: 200),
            ),
            const SizedBox(height: 16),
            Text(
              'Capturing evidence...',
              style: TextStyle(
                color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongCodeOverlay() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        return Container(
          color: UnseenTheme.bloodRed.withValues(alpha: 0.1 + (_glitchController.value * 0.2)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: UnseenTheme.bloodRed,
                  size: 80,
                ),
                const SizedBox(height: 16),
                GlitchText(
                  text: _errorMessage ?? 'Wrong location',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: UnseenTheme.bloodRed,
                  ),
                  enableGlitch: true,
                  glitchInterval: const Duration(milliseconds: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Close button
              _buildIconButton(
                icon: Icons.close,
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              // Virtual QR Mode toggle
              _buildIconButton(
                icon: _virtualQrMode ? Icons.qr_code_2 : Icons.qr_code_scanner,
                onPressed: () {
                  final enablingVirtual = !_virtualQrMode;
                  setState(() {
                    _virtualQrMode = enablingVirtual;
                    _isScanning = !_clueFound; // Keep scan flow active unless clue already found
                    _wrongCodeScanned = false;
                    _errorMessage = null;
                    _lastScannedCode = null;
                  });
                  HapticService().lightImpact();
                },
                isActive: _virtualQrMode,
              ),
              const SizedBox(width: 8),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _clueFound
                        ? UnseenTheme.toxicGreen.withValues(alpha: 0.5)
                        : UnseenTheme.bloodRed.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _clueFound
                            ? UnseenTheme.toxicGreen
                            : (_wrongCodeScanned
                                ? UnseenTheme.bloodRed
                                : UnseenTheme.decayYellow),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _clueFound
                          ? 'FOUND'
                          : (_wrongCodeScanned
                              ? 'WRONG'
                              : (_virtualQrMode ? 'VIRTUAL' : 'SCANNING')),
                      style: TextStyle(
                        color: UnseenTheme.boneWhite,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Torch button (only show in physical scan mode)
              if (!_virtualQrMode)
                _buildIconButton(
                  icon: _torchEnabled ? Icons.flash_on : Icons.flash_off,
                  onPressed: _toggleTorch,
                  isActive: _torchEnabled,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? UnseenTheme.decayYellow.withValues(alpha: 0.5)
                : UnseenTheme.bloodRed.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? UnseenTheme.decayYellow : UnseenTheme.boneWhite,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildVirtualQrOverlay() {
    final huntProvider = context.watch<HuntProvider>();
    final currentClue = _getCurrentClue(huntProvider);

    if (currentClue.qrCode == null || currentClue.qrCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = _pulseController.value;
          final glowAlpha = 0.5 + (pulseValue * 0.3);
          return Container(
            margin: const EdgeInsets.only(bottom: 200), // Add bottom margin to avoid overlap with bottom panel
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UnseenTheme.voidBlack.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: UnseenTheme.bloodRed.withValues(alpha: glowAlpha),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: UnseenTheme.bloodRed.withValues(alpha: glowAlpha),
                  blurRadius: 30 + (pulseValue * 25),
                  spreadRadius: 10 + (pulseValue * 6),
                ),
                BoxShadow(
                  color: UnseenTheme.voidBlack.withValues(alpha: 0.75),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.qr_code_2,
                      color: UnseenTheme.bloodRed,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'VIRTUAL QR CODE',
                      style: TextStyle(
                        color: UnseenTheme.bloodRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: UnseenTheme.boneWhite.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: UnseenTheme.bloodRed.withValues(alpha: 0.15 + (pulseValue * 0.15)),
                        blurRadius: 18 + (pulseValue * 10),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: currentClue.qrCode!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: UnseenTheme.boneWhite,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: UnseenTheme.voidBlack,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: UnseenTheme.voidBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _handleQrValue(currentClue.qrCode!, fromVirtual: true);
                    },
                    icon: const Icon(Icons.sensor_occupied),
                    label: const Text('SCAN VIRTUAL QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UnseenTheme.bloodRed,
                      foregroundColor: UnseenTheme.boneWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomInfo() {
    final huntProvider = context.watch<HuntProvider>();
    final currentClue = _getCurrentClue(huntProvider);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: UnseenTheme.voidBlack.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: UnseenTheme.bloodRed.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: UnseenTheme.bloodRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _virtualQrMode ? Icons.qr_code_2 : Icons.qr_code_scanner,
                      color: UnseenTheme.bloodRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _virtualQrMode ? 'VIRTUAL QR MODE' : 'SCAN THE QR CODE',
                          style: const TextStyle(
                            color: UnseenTheme.boneWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _virtualQrMode
                              ? 'Digital target rendered on screen'
                              : 'Find the hidden code at the location',
                          style: TextStyle(
                            color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: UnseenTheme.shadowGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: UnseenTheme.decayYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentClue.hint,
                        style: TextStyle(
                          color: UnseenTheme.sicklyCream,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if ((currentClue.locationHint ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: UnseenTheme.toxicGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentClue.locationHint ?? '',
                        style: TextStyle(
                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // QR Code preview
              if (currentClue.qrCode != null && currentClue.qrCode!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UnseenTheme.voidBlack.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: UnseenTheme.bloodRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UnseenTheme.boneWhite,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: QrImageView(
                          data: currentClue.qrCode!,
                          version: QrVersions.auto,
                          size: 60,
                          backgroundColor: UnseenTheme.boneWhite,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: UnseenTheme.voidBlack,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: UnseenTheme.voidBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOOKING FOR:',
                              style: TextStyle(
                                color: UnseenTheme.bloodRed,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentClue.qrCode!,
                              style: TextStyle(
                                color: UnseenTheme.sicklyCream.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Clue _getCurrentClue(HuntProvider huntProvider) {
    return huntProvider.currentClues.firstWhere(
      (c) => c.id == widget.clueId,
      orElse: () => huntProvider.currentClues.first,
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  final double size;
  final Color color;
  final _Corner corner;

  const _CornerBracket({
    required this.size,
    required this.color,
    required this.corner,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          corner: corner,
          color: color,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final _Corner corner;
  final Color color;

  _CornerPainter({
    required this.corner,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height * 0.6);
        path.lineTo(0, 0);
        path.lineTo(size.width * 0.6, 0);
        break;
      case _Corner.topRight:
        path.moveTo(size.width * 0.4, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height * 0.6);
        break;
      case _Corner.bottomLeft:
        path.moveTo(0, size.height * 0.4);
        path.lineTo(0, size.height);
        path.lineTo(size.width * 0.6, size.height);
        break;
      case _Corner.bottomRight:
        path.moveTo(size.width * 0.4, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, size.height * 0.4);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
