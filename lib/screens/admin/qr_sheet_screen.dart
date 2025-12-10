import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/models/clue.dart';
import 'package:unseen/models/hunt.dart';
import 'package:unseen/services/firestore_service.dart';
import 'package:unseen/widgets/common/glitch_text.dart';

class QrSheetScreen extends StatefulWidget {
  final String huntId;

  const QrSheetScreen({super.key, required this.huntId});

  @override
  State<QrSheetScreen> createState() => _QrSheetScreenState();
}

class _QrSheetScreenState extends State<QrSheetScreen> {
  final _firestore = FirestoreService();
  Hunt? _hunt;
  List<Clue> _clues = [];
  bool _loading = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final hunt = await _firestore.getHunt(widget.huntId);
      final clues = await _firestore.getCluesForHunt(widget.huntId);
      if (!mounted) return;
      setState(() {
        _hunt = hunt;
        _clues = clues;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load hunt: $e'),
          backgroundColor: UnseenTheme.bloodRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSheet() async {
    try {
      final bytes = await _screenshotController.capture(delay: const Duration(milliseconds: 200));
      if (bytes == null) return;
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(bytes),
        quality: 95,
        name: 'unseen_${widget.huntId}_qr_sheet',
      );
      if (!mounted) return;
      final success = result['isSuccess'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Saved to gallery' : 'Saved image (check gallery)'),
          backgroundColor: success ? UnseenTheme.toxicGreen : UnseenTheme.decayYellow,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: UnseenTheme.bloodRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const GlitchText(text: 'QR SHEET', enableGlitch: false),
        actions: [
          IconButton(
            onPressed: _clues.isEmpty ? null : _saveSheet,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: UnseenTheme.bloodRed))
          : (_hunt == null
              ? Center(
                  child: Text(
                    'Hunt not found',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: UnseenTheme.sicklyCream),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'UNSEEN – ${_hunt!.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hunt!.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ..._clues.map((clue) => _buildQrTile(clue)),
                        ],
                      ),
                    ),
                  ),
                )),
    );
  }

  Widget _buildQrTile(Clue clue) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          QrImageView(
            data: clue.qrCode ?? 'UNSEEN_CLUE',
            size: 110,
            version: QrVersions.auto,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clue ${clue.order}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clue.hint,
                  style: const TextStyle(fontSize: 14),
                ),
                if ((clue.locationHint ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Place near: ${clue.locationHint}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
