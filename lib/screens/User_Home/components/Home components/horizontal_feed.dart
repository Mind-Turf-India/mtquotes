import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:mtquotes/providers/text_size_provider.dart';

// Generic horizontal section widget that can be reused across the app
class HorizontalSection<T> extends StatelessWidget {
  final String title;
  final String viewAllRoute;
  final Future<List<T>> Function() fetchItems;
  final Widget Function(T item) itemBuilder;
  final bool Function(T item)? filterItem;
  final int maxItems;
  final double itemWidth;
  final double itemHeight;
  final String noItemsMessage;

  const HorizontalSection({
    Key? key,
    required this.title,
    required this.viewAllRoute,
    required this.fetchItems,
    required this.itemBuilder,
    this.filterItem,
    this.maxItems = 10,
    this.itemWidth = 100.0,
    this.itemHeight = 150.0,
    this.noItemsMessage = 'No items available',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with title and view all button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, viewAllRoute);
                },
                child: Text(
                  context.loc.viewall,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Item list
        SizedBox(
          height: itemHeight,
          child: FutureBuilder<List<T>>(
            future: fetchItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize - 2,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    noItemsMessage,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize - 2,
                      color: AppColors.getTextColor(isDarkMode),
                    ),
                  ),
                );
              }

              // Filter items if filter provided
              List<T> displayItems = filterItem != null
                  ? snapshot.data!.where(filterItem!).toList()
                  : snapshot.data!;

              // Limit number of items
              if (displayItems.length > maxItems) {
                displayItems = displayItems.sublist(0, maxItems);
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return Container(
                    width: itemWidth,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    child: itemBuilder(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Item card for templates/posts in horizontal sections with zoom effect
class ItemCard extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final bool isPremium;
  final VoidCallback onTap;
  final double borderRadius;
  final double? aspectRatio;

  const ItemCard({
    Key? key,
    required this.imageUrl,
    this.title,
    this.isPremium = false,
    required this.onTap,
    this.borderRadius = 8.0,
    this.aspectRatio,
  }) : super(key: key);

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? Colors.transparent
                    : isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.shade300,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                widget.aspectRatio != null
                    ? AspectRatio(
                  aspectRatio: widget.aspectRatio!,
                  child: _buildImage(),
                )
                    : _buildImage(),

                // Title overlay (if provided)
                if (widget.title != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        widget.title!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Premium badge
                if (widget.isPremium)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/premium_1659060.svg',
                        width: 16,
                        height: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.white70 : Colors.black45,
              ),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
        ),
      ),
    );
  }
}