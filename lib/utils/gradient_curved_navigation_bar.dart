import 'package:mtquotes/utils/nav_gradient_painter.dart';
import 'package:universal_io/io.dart';
import 'dart:math';

import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:curved_labeled_navigation_bar/src/nav_bar_item_widget.dart';
import 'package:curved_labeled_navigation_bar/src/nav_custom_clipper.dart';
import 'package:flutter/material.dart';

typedef _LetIndexPage = bool Function(int value);

class GradientCurvedNavigationBar extends StatefulWidget {
  /// Defines the appearance of the [CurvedNavigationBarItem] list that are
  /// arrayed within the bottom navigation bar.
  final List<CurvedNavigationBarItem> items;

  /// The index into [items] for the current active [CurvedNavigationBarItem].
  final int index;

  /// The gradient colors of the [GradientCurvedNavigationBar]
  final List<Color> gradientColors;

  /// The gradient begin position
  final Alignment gradientBegin;

  /// The gradient end position
  final Alignment gradientEnd;

  /// Whether to use gradient for the floating button background
  final bool useGradientButton;

  /// The background color of floating button, default same as first color in gradientColors.
  final Color? buttonBackgroundColor;

  /// The color of [GradientCurvedNavigationBar]'s background, default Colors.blueAccent.
  final Color backgroundColor;

  /// Called when one of the [items] is tapped.
  final ValueChanged<int>? onTap;

  /// Function which takes page index as argument and returns bool. If function
  /// returns false then page is not changed on button tap. It returns true by
  /// default.
  final _LetIndexPage letIndexChange;

  /// Curves interpolating button change animation, default Curves.easeOut.
  final Curve animationCurve;

  /// Duration of button change animation, default Duration(milliseconds: 600).
  final Duration animationDuration;

  /// Height of [GradientCurvedNavigationBar].
  final double height;

  /// Max width of [GradientCurvedNavigationBar].
  final double? maxWidth;

  /// Padding of icon in floating button.
  final double iconPadding;

  /// Check if [GradientCurvedNavigationBar] has label.
  final bool hasLabel;

  GradientCurvedNavigationBar({
    Key? key,
    required this.items,
    this.index = 0,
    required this.gradientColors,
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
    this.useGradientButton = true,
    this.buttonBackgroundColor,
    this.backgroundColor = Colors.blueAccent,
    this.onTap,
    _LetIndexPage? letIndexChange,
    this.animationCurve = Curves.easeOut,
    this.animationDuration = const Duration(milliseconds: 600),
    this.iconPadding = 12.0,
    this.maxWidth,
    double? height,
  })  : letIndexChange = letIndexChange ?? ((_) => true),
        assert(items.isNotEmpty),
        assert(0 <= index && index < items.length),
        assert(maxWidth == null || 0 <= maxWidth),
        assert(gradientColors.length >= 2, "At least 2 colors are required for gradient"),
        height = height ?? (Platform.isAndroid ? 70.0 : 80.0),
        hasLabel = items.any((item) => item.label != null),
        super(key: key);

  @override
  GradientCurvedNavigationBarState createState() => GradientCurvedNavigationBarState();
}

class GradientCurvedNavigationBarState extends State<GradientCurvedNavigationBar>
    with SingleTickerProviderStateMixin {
  late double _startingPos;
  late int _endingIndex;
  late double _pos;
  late Widget _icon;
  late AnimationController _animationController;
  late int _length;
  double _buttonHide = 0;

  @override
  void initState() {
    super.initState();
    _icon = widget.items[widget.index].child;
    _length = widget.items.length;
    _pos = widget.index / _length;
    _startingPos = widget.index / _length;
    _endingIndex = widget.index;
    _animationController = AnimationController(vsync: this, value: _pos);
    _animationController.addListener(() {
      setState(() {
        _pos = _animationController.value;
        final endingPos = _endingIndex / widget.items.length;
        final middle = (endingPos + _startingPos) / 2;
        if ((endingPos - _pos).abs() < (_startingPos - _pos).abs()) {
          _icon = widget.items[_endingIndex].child;
        }
        _buttonHide =
            (1 - ((middle - _pos) / (_startingPos - middle)).abs()).abs();
      });
    });
  }

  @override
  void didUpdateWidget(GradientCurvedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final newPosition = widget.index / _length;
      _startingPos = _pos;
      _endingIndex = widget.index;
      _animationController.animateTo(
        newPosition,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      );
    }
    if (!_animationController.isAnimating) {
      _icon = widget.items[_endingIndex].child;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = min(
              constraints.maxWidth, widget.maxWidth ?? constraints.maxWidth);
          return Align(
            alignment: textDirection == TextDirection.ltr
                ? Alignment.bottomLeft
                : Alignment.bottomRight,
            child: Container(
              color: widget.backgroundColor,
              width: maxWidth,
              child: ClipRect(
                clipper: NavCustomClipper(
                  deviceHeight: MediaQuery.sizeOf(context).height,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    // Floating button with gradient or solid color
                    Positioned(
                      bottom: widget.height - 105.0,
                      left: textDirection == TextDirection.rtl
                          ? null
                          : _pos * maxWidth,
                      right: textDirection == TextDirection.rtl
                          ? _pos * maxWidth
                          : null,
                      width: maxWidth / _length,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, (_buttonHide - 1) * 80),
                          child: widget.useGradientButton
                              ? _buildGradientButton()
                              : Material(
                                  color: widget.buttonBackgroundColor ?? 
                                         widget.gradientColors.first,
                                  type: MaterialType.circle,
                                  child: Padding(
                                    padding: EdgeInsets.all(widget.iconPadding),
                                    child: _icon,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Background with gradient
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        painter: NavGradientPainter(
                          startingLoc: _pos,
                          itemsLength: _length,
                          gradientColors: widget.gradientColors,
                          gradientBegin: widget.gradientBegin,
                          gradientEnd: widget.gradientEnd,
                          textDirection: Directionality.of(context),
                          hasLabel: widget.hasLabel,
                        ),
                        child: Container(height: widget.height),
                      ),
                    ),
                    // Unselected buttons
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        height: widget.height,
                        child: Row(
                          children: widget.items.map((item) {
                            return NavBarItemWidget(
                              onTap: _buttonTap,
                              position: _pos,
                              length: _length,
                              index: widget.items.indexOf(item),
                              child: Center(child: item.child),
                              label: item.label,
                              labelStyle: item.labelStyle,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // New method to build a button with gradient background
  Widget _buildGradientButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: widget.gradientBegin,
          end: widget.gradientEnd,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.iconPadding),
        child: _icon,
      ),
    );
  }

  void setPage(int index) {
    _buttonTap(index);
  }

  void _buttonTap(int index) {
    if (!widget.letIndexChange(index) || _animationController.isAnimating) {
      return;
    }
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
    final newPosition = index / _length;
    setState(() {
      _startingPos = _pos;
      _endingIndex = index;
      _animationController.animateTo(
        newPosition,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      );
    });
  }
}