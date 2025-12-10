import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/models/clue.dart';
import 'package:unseen/models/hunt.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/services/firestore_service.dart';
import 'package:unseen/services/qr_service.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HuntBuilderScreen extends StatefulWidget {
  const HuntBuilderScreen({super.key});

  @override
  State<HuntBuilderScreen> createState() => _HuntBuilderScreenState();
}

class _HuntBuilderScreenState extends State<HuntBuilderScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedTimeController = TextEditingController(text: '30 min');
  String _difficulty = 'nightmare';
  bool _isAvailable = true;
  bool _isSaving = false;

  final List<_ClueFormData> _clues = [];
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _addClue();
    _addClue();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    for (final clue in _clues) {
      clue.dispose();
    }
    super.dispose();
  }

  String _pendingHuntId() {
    return QrService.generateHuntId(_nameController.text.trim().isEmpty
        ? 'unseen_hunt'
        : _nameController.text.trim());
  }

  void _addClue() {
    final order = _clues.length + 1;
    final clue = _ClueFormData(
      order: order,
      qrCode: QrService.generateClueCode(
        huntId: _pendingHuntId(),
        order: order,
      ),
    );
    setState(() {
      _clues.add(clue);
    });
  }

  void _removeClue(int index) {
    if (_clues.length <= 1) return;
    setState(() {
      _clues.removeAt(index).dispose();
      for (int i = 0; i < _clues.length; i++) {
        _clues[i].order = i + 1;
      }
    });
  }

  Future<void> _saveHunt() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and description are required'),
          backgroundColor: UnseenTheme.bloodRed,
        ),
      );
      return;
    }

    if (_clues.any((c) => c.hint.text.trim().isEmpty || c.narrative.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each clue needs at least a hint and narrative'),
          backgroundColor: UnseenTheme.bloodRed,
        ),
      );
      return;
    }

    final huntId = QrService.generateHuntId(name);
    setState(() => _isSaving = true);

    try {
      final clueIds = <String>[];
      final clues = <Clue>[];
      final uuid = const Uuid();

      for (var i = 0; i < _clues.length; i++) {
        final form = _clues[i];
        final clueId = '${huntId}_clue_${i + 1}_${uuid.v4().split('-').first}';
        clueIds.add(clueId);
        final qr = QrService.generateClueCode(
          huntId: huntId,
          order: i + 1,
        );
        clues.add(
          Clue(
            id: clueId,
            huntId: huntId,
            order: i + 1,
            hint: form.hint.text.trim(),
            fullHint: form.fullHint.text.trim().isEmpty
                ? form.hint.text.trim()
                : form.fullHint.text.trim(),
            narrative: form.narrative.text.trim(),
            qrCode: qr,
            locationHint: form.locationHint.text.trim(),
          ),
        );
      }

      final hunt = Hunt(
        id: huntId,
        name: name,
        description: description,
        difficulty: _difficulty,
        clueCount: clues.length,
        clueIds: clueIds,
        isAvailable: _isAvailable,
        estimatedTime: _estimatedTimeController.text.trim(),
      );

      await _firestore.createHunt(hunt);
      for (final clue in clues) {
        await _firestore.createClue(clue);
      }

      if (!mounted) return;
      context.read<HuntProvider>().loadHunts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hunt "$name" created'),
          backgroundColor: UnseenTheme.toxicGreen,
        ),
      );
      context.go('${RouteNames.adminQrSheet}/$huntId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save hunt: $e'),
          backgroundColor: UnseenTheme.bloodRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const GlitchText(
          text: 'BUILD A HUNT',
          enableGlitch: false,
        ),
        actions: [
          IconButton(
            onPressed: _addClue,
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add clue',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHuntMetaCard(),
              const SizedBox(height: 16),
              ..._clues.asMap().entries.map((entry) {
                final idx = entry.key;
                final clue = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildClueCard(clue, idx),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addClue,
                icon: const Icon(Icons.add),
                label: const Text('ADD CLUE'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: UnseenTheme.bloodRed),
                  foregroundColor: UnseenTheme.bloodRed,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveHunt,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: UnseenTheme.boneWhite,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'SAVING...' : 'SAVE HUNT & GENERATE QRS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UnseenTheme.bloodRed,
                  foregroundColor: UnseenTheme.boneWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHuntMetaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UnseenTheme.shadowGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UnseenTheme.bloodRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Hunt name',
            ),
            style: const TextStyle(color: UnseenTheme.boneWhite),
            onChanged: (_) {
              // Regenerate QR seeds so codes reflect the new hunt id
              for (int i = 0; i < _clues.length; i++) {
                _clues[i].qrCode = QrService.generateClueCode(
                  huntId: _pendingHuntId(),
                  order: i + 1,
                );
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
            maxLines: 2,
            style: const TextStyle(color: UnseenTheme.boneWhite),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    DropdownMenuItem(value: 'nightmare', child: Text('Nightmare')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _difficulty = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _estimatedTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated time',
                    hintText: 'e.g. 30 min',
                  ),
                  style: const TextStyle(color: UnseenTheme.boneWhite),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            title: const Text('Make available to players'),
            activeTrackColor: UnseenTheme.toxicGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildClueCard(_ClueFormData clue, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UnseenTheme.shadowGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UnseenTheme.bloodRed.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: UnseenTheme.bloodRed.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlitchText(
                text: 'CLUE ${clue.order}',
                enableGlitch: false,
                style: const TextStyle(
                  color: UnseenTheme.boneWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeClue(index),
                icon: const Icon(Icons.delete_forever, color: UnseenTheme.bloodRed),
              ),
            ],
          ),
          TextField(
            controller: clue.hint,
            decoration: const InputDecoration(labelText: 'Hint'),
            style: const TextStyle(color: UnseenTheme.boneWhite),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: clue.fullHint,
            decoration: const InputDecoration(
              labelText: 'Full hint (optional)',
            ),
            maxLines: 2,
            style: const TextStyle(color: UnseenTheme.boneWhite),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: clue.locationHint,
            decoration: const InputDecoration(
              labelText: 'Location hint (where to hide the QR)',
            ),
            maxLines: 2,
            style: const TextStyle(color: UnseenTheme.boneWhite),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: clue.narrative,
            decoration: const InputDecoration(
              labelText: 'Narrative reveal',
            ),
            maxLines: 3,
            style: const TextStyle(color: UnseenTheme.boneWhite),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  clue.qrCode,
                  style: const TextStyle(
                    color: UnseenTheme.sicklyCream,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Regenerate QR code',
                onPressed: () {
                  setState(() {
                    clue.qrCode = QrService.generateClueCode(
                      huntId: _pendingHuntId(),
                      order: clue.order,
                    );
                  });
                },
                icon: const Icon(Icons.refresh, color: UnseenTheme.decayYellow),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: UnseenTheme.voidBlack.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: UnseenTheme.bloodRed.withValues(alpha: 0.4)),
                ),
                child: QrImageView(
                  data: clue.qrCode,
                  version: QrVersions.auto,
                  size: 56,
                  backgroundColor: Colors.transparent,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: UnseenTheme.bloodRed,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: UnseenTheme.boneWhite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClueFormData {
  _ClueFormData({
    required this.order,
    required this.qrCode,
  });

  int order;
  String qrCode;
  final TextEditingController hint = TextEditingController();
  final TextEditingController fullHint = TextEditingController();
  final TextEditingController narrative = TextEditingController();
  final TextEditingController locationHint = TextEditingController();

  void dispose() {
    hint.dispose();
    fullHint.dispose();
    narrative.dispose();
    locationHint.dispose();
  }
}
