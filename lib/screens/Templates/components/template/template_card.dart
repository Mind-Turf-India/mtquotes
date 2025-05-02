import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../utils/app_colors.dart';
import '../../../User_Home/components/tapp_effect.dart';

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

    return TapEffectWidget(
      onTap: onTap,
      scaleEffect: 0.85, // More noticeable scale effect
      opacityEffect: 0.99,
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
                      // child: CircularProgressIndicator(
                      //   strokeWidth: 2,
                      //   color: theme.primaryColor,
                      // ),
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
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 24,
                      height: 24,
                      color: Colors.amber,
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