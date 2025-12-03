import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unseen/config/theme.dart';
import 'package:unseen/utils/constants.dart';
import 'package:unseen/widgets/common/glitch_text.dart';
import 'package:unseen/providers/hunt_provider.dart';
import 'package:unseen/models/hunt.dart';

class HuntSelectScreen extends StatefulWidget {
  const HuntSelectScreen({super.key});

  @override
  State<HuntSelectScreen> createState() => _HuntSelectScreenState();
}

class _HuntSelectScreenState extends State<HuntSelectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _selectedDifficulty = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Load hunts from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HuntProvider>().loadHunts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'nightmare':
        return UnseenTheme.bloodRed;
      case 'hard':
        return Colors.orange;
      case 'medium':
        return UnseenTheme.decayYellow;
      case 'easy':
        return UnseenTheme.toxicGreen;
      default:
        return UnseenTheme.sicklyCream;
    }
  }

  List<Hunt> _getFilteredHunts(List<Hunt> hunts) {
    return hunts.where((hunt) {
      // Difficulty filter
      if (_selectedDifficulty != 'all' &&
          hunt.difficulty.toLowerCase() != _selectedDifficulty.toLowerCase()) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        if (!hunt.name.toLowerCase().contains(query) &&
            !hunt.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final huntProvider = context.watch<HuntProvider>();
    final filteredHunts = _getFilteredHunts(huntProvider.hunts);

    return Scaffold(
      backgroundColor: UnseenTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const GlitchText(
          text: 'SELECT HUNT',
          enableGlitch: false,
        ),
        actions: [
          IconButton(
            tooltip: 'Create hunt (admin)',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => context.push(RouteNames.adminHuntBuilder),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: huntProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: UnseenTheme.bloodRed,
                ),
              )
            : huntProvider.hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: UnseenTheme.bloodRed,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong...',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            huntProvider.errorMessage ?? 'Failed to load hunts',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: UnseenTheme.sicklyCream.withValues(alpha: 0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => huntProvider.loadHunts(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('RETRY'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UnseenTheme.bloodRed,
                              foregroundColor: UnseenTheme.boneWhite,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : huntProvider.hunts.isEmpty
                    ? Center(
                        child: Text(
                          'No hunts available...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : Column(
                        children: [
                          // Search and filter bar
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Search bar
                                TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: UnseenTheme.boneWhite),
                                  decoration: InputDecoration(
                                    hintText: 'Search hunts...',
                                    hintStyle: TextStyle(
                                      color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: UnseenTheme.bloodRed,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              color: UnseenTheme.sicklyCream,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: UnseenTheme.shadowGray,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: UnseenTheme.bloodRed.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: UnseenTheme.bloodRed,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Difficulty filter
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _FilterChip(
                                        label: 'All',
                                        isSelected: _selectedDifficulty == 'all',
                                        onTap: () {
                                          setState(() {
                                            _selectedDifficulty = 'all';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: 'Easy',
                                        isSelected: _selectedDifficulty == 'easy',
                                        onTap: () {
                                          setState(() {
                                            _selectedDifficulty = 'easy';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: 'Medium',
                                        isSelected: _selectedDifficulty == 'medium',
                                        onTap: () {
                                          setState(() {
                                            _selectedDifficulty = 'medium';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: 'Hard',
                                        isSelected: _selectedDifficulty == 'hard',
                                        onTap: () {
                                          setState(() {
                                            _selectedDifficulty = 'hard';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: 'Nightmare',
                                        isSelected: _selectedDifficulty == 'nightmare',
                                        onTap: () {
                                          setState(() {
                                            _selectedDifficulty = 'nightmare';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Hunt list
                          Expanded(
                            child: filteredHunts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          color: UnseenTheme.sicklyCream.withValues(alpha: 0.3),
                                          size: 64,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hunts match your filters...',
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your search or filters',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: UnseenTheme.sicklyCream.withValues(alpha: 0.5),
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () async {
                                      await huntProvider.loadHunts();
                                    },
                                    color: UnseenTheme.bloodRed,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: filteredHunts.length,
                                      itemBuilder: (context, index) {
                                        final hunt = filteredHunts[index];
                                        return _HuntCard(
                                          hunt: hunt,
                                          difficultyColor: _getDifficultyColor(hunt.difficulty),
                                          onTap: () {
                                            if (hunt.isAvailable) {
                                              HapticFeedback.mediumImpact();
                                              context.push('${RouteNames.hunt}/${hunt.id}');
                                            } else {
                                              HapticFeedback.heavyImpact();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('This hunt is not yet available...'),
                                                ),
                                              );
                                            }
                                          },
                                          animationDelay: Duration(milliseconds: 100 * index),
                                        );
                                      },
                                    ),
                                    ),
                          ),
                          ],
                        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? UnseenTheme.bloodRed.withValues(alpha: 0.2)
              : UnseenTheme.shadowGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? UnseenTheme.bloodRed
                : UnseenTheme.sicklyCream.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? UnseenTheme.bloodRed
                : UnseenTheme.sicklyCream.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _HuntCard extends StatefulWidget {
  final Hunt hunt;
  final Color difficultyColor;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _HuntCard({
    required this.hunt,
    required this.difficultyColor,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_HuntCard> createState() => _HuntCardState();
}

class _HuntCardState extends State<_HuntCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: UnseenTheme.shadowGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.hunt.isAvailable
                    ? UnseenTheme.bloodRed.withValues(alpha: 0.3)
                    : UnseenTheme.sicklyCream.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              children: [
                // Locked overlay
                if (!widget.hunt.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: UnseenTheme.voidBlack.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: UnseenTheme.sicklyCream,
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.hunt.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: widget.hunt.isAvailable
                                        ? UnseenTheme.boneWhite
                                        : UnseenTheme.sicklyCream
                                            .withValues(alpha: 0.5),
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.difficultyColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.difficultyColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.hunt.difficulty,
                              style: TextStyle(
                                color: widget.difficultyColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        widget.hunt.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.hunt.isAvailable
                                  ? UnseenTheme.sicklyCream.withValues(alpha: 0.8)
                                  : UnseenTheme.sicklyCream.withValues(alpha: 0.4),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.search,
                            label: '${widget.hunt.clueCount} clues',
                            isAvailable: widget.hunt.isAvailable,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.timer,
                            label: widget.hunt.estimatedTime ?? 'N/A',
                            isAvailable: widget.hunt.isAvailable,
                          ),
                          const Spacer(),
                          if (widget.hunt.isAvailable)
                            Icon(
                              Icons.play_circle_fill,
                              color:
                                  UnseenTheme.bloodRed.withValues(alpha: 0.8),
                              size: 32,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAvailable;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isAvailable
              ? UnseenTheme.sicklyCream.withValues(alpha: 0.6)
              : UnseenTheme.sicklyCream.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isAvailable
                ? UnseenTheme.sicklyCream.withValues(alpha: 0.6)
                : UnseenTheme.sicklyCream.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
