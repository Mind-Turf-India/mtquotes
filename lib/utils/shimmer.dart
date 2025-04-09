import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final bool isDarkMode;
  final ShimmerType type;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    Key? key,
    this.width = 100,
    this.height = 100,
    required this.isDarkMode,
    this.type = ShimmerType.simple,
    this.margin = const EdgeInsets.only(right: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        margin: margin,
        width: width,
        height: height,
        child: _buildShimmerContent(),
      ),
    );
  }

  Widget _buildShimmerContent() {
    switch (type) {
      case ShimmerType.template:
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
        );

      case ShimmerType.festival:
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
          child: Column(
            children: [
              // Festival image placeholder
              Container(
                height: height * 0.7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
              // Festival name placeholder
              Container(
                margin: const EdgeInsets.only(top: 8, left: 6, right: 6),
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        );

      case ShimmerType.category:
        return Column(
          children: [
            // Circular category image placeholder
            Container(
              width: width * 0.8,
              height: height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            // Category name placeholder
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 10,
              width: width * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        );

      case ShimmerType.simple:
      default:
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
        );
    }
  }
}

// Enum to specify the type of shimmer effect
enum ShimmerType {
  simple,    // Basic rectangle
  template,  // For template items
  festival,  // For festival items
  category,  // For category items with circular image
}

// Horizontal list of shimmer loaders
class ShimmerHorizontalList extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;
  final bool isDarkMode;
  final ShimmerType type;

  const ShimmerHorizontalList({
    Key? key,
    this.itemCount = 5,
    this.itemWidth = 100,
    this.itemHeight = 100,
    required this.isDarkMode,
    this.type = ShimmerType.simple,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoader(
          width: itemWidth,
          height: itemHeight,
          isDarkMode: isDarkMode,
          type: type,
        );
      },
    );
  }
}