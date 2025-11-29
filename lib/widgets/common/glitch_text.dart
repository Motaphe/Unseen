import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool enableGlitch;
  final Duration glitchInterval;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.enableGlitch = true,
    this.glitchInterval = const Duration(milliseconds: 2000),
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _glitchTimer;
  bool _isGlitching = false;
  final Random _random = Random();

  // Glitch characters
  static const String _glitchChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    if (widget.enableGlitch) {
      _startGlitchTimer();
    }
  }

  void _startGlitchTimer() {
    _glitchTimer = Timer.periodic(widget.glitchInterval, (_) {
      if (mounted && _random.nextDouble() < 0.3) {
        _triggerGlitch();
      }
    });
  }

  void _triggerGlitch() async {
    if (!mounted) return;
    setState(() => _isGlitching = true);

    // Quick glitch effect
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) setState(() => _isGlitching = false);
  }

  String _getGlitchedText() {
    if (!_isGlitching) return widget.text;

    final chars = widget.text.split('');
    final glitchCount = _random.nextInt(3) + 1;

    for (var i = 0; i < glitchCount; i++) {
      final index = _random.nextInt(chars.length);
      chars[index] = _glitchChars[_random.nextInt(_glitchChars.length)];
    }

    return chars.join();
  }

  @override
  void dispose() {
    _controller.dispose();
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main text
        Text(
          _getGlitchedText(),
          style: widget.style,
        ),
        // Red offset (glitch effect)
        if (_isGlitching)
          Positioned(
            left: _random.nextDouble() * 4 - 2,
            top: _random.nextDouble() * 2 - 1,
            child: Text(
              widget.text,
              style: widget.style?.copyWith(
                color: Colors.red.withValues(alpha: 0.7),
              ),
            ),
          ),
        // Cyan offset (glitch effect)
        if (_isGlitching)
          Positioned(
            left: _random.nextDouble() * -4 + 2,
            top: _random.nextDouble() * 2 - 1,
            child: Text(
              widget.text,
              style: widget.style?.copyWith(
                color: Colors.cyan.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 50),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: _displayedText,
        style: widget.style ?? Theme.of(context).textTheme.bodyLarge,
        children: [
          // Blinking cursor
          TextSpan(
            text: _currentIndex < widget.text.length ? '|' : '',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
