import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TemplateCard extends StatelessWidget {
  final QuoteTemplate template;
  final double fontSize;
  final VoidCallback onTap;

  const TemplateCard({
    Key? key,
    required this.template,
    required this.fontSize,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 80,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? Colors.black26 
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
              template.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: template.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.error,
                          color: theme.iconTheme.color,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ),
              
              // Premium badge if needed
              if (template.isPaid)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.amber, size: 12),
                        SizedBox(width: 2),
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
                
              // Optional title overlay at bottom (similar to RecentTemplatesSection)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    template.title.isNotEmpty
                        ? template.title
                        : template.category.isNotEmpty
                            ? template.category
                            : "Template",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: fontSize - 4,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
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