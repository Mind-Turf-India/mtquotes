import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';

class FestivalCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Get the theme information
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
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
              Image.network(
                festival.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
                    child: Center(
                      child: Text(
                        festival.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize - 2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (festival.isPaid)
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
                        Icon(Icons.lock, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
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
            ],
          ),
        ),
      ),
    );
  }
}