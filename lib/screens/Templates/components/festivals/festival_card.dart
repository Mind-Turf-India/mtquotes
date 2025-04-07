import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FestivalCard extends StatefulWidget {
  final FestivalPost festival;
  final double fontSize;
  final VoidCallback onTap;

  const FestivalCard({
    Key? key,
    required this.festival,
    required this.fontSize,
    required this.onTap,
  }) : super(key: key);

  @override
  State<FestivalCard> createState() => _FestivalCardState();
}

class _FestivalCardState extends State<FestivalCard> {
  bool _isLoading = false;

  void _handleTap() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call the original onTap handler
      widget.onTap();
    } finally {
      // If the widget is still mounted, set loading to false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme information
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 100, // Same as TemplateCard
        height: 80, // Same as TemplateCard
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.shade300,
              blurRadius: 5
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Using CachedNetworkImage for better performance and error handling
              CachedNetworkImage(
                imageUrl: widget.festival.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDarkMode ? Colors.blue : theme.primaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      widget.festival.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: widget.fontSize - 2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
              
              // PRO badge overlay
              if (widget.festival.isPaid)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? Colors.black.withOpacity(0.8) 
                        : Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              // Tap loading indicator overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white : theme.primaryColor,
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}