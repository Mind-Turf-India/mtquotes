import 'package:flutter/material.dart';

class TapEffectWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleEffect;
  final double opacityEffect;
  final Duration duration;

  const TapEffectWidget({
    Key? key,
    required this.child,
    required this.onTap,
    this.scaleEffect = 0.95,
    this.opacityEffect = 0.9,
    this.duration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<TapEffectWidget> createState() => _TapEffectWidgetState();
}

class _TapEffectWidgetState extends State<TapEffectWidget> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: widget.duration,
        opacity: _isTapped ? widget.opacityEffect : 1.0,
        child: AnimatedScale(
          duration: widget.duration,
          scale: _isTapped ? widget.scaleEffect : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

