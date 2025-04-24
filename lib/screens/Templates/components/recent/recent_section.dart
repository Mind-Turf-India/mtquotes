import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/providers/text_size_provider.dart';

import 'package:mtquotes/l10n/app_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentTemplatesSection extends StatelessWidget {
  final List<QuoteTemplate> recentTemplates;
  final Function(QuoteTemplate) onTemplateSelected;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const RecentTemplatesSection({
    super.key,
    required this.recentTemplates,
    required this.onTemplateSelected,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    double fontSize = textSizeProvider.fontSize;
    final isUserLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.loc.recents,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            if (onViewAll != null && recentTemplates.isNotEmpty)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  context.loc.viewall,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    color: theme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: theme.primaryColor))
              : !isUserLoggedIn
                  ? Center(
                      child: Text(
                        "Sign in to view recent templates",
                        style: GoogleFonts.poppins(
                          fontSize: fontSize - 2,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    )
                  : recentTemplates.isEmpty
                      ? Center(
                          child: Text(
                            context.loc.norecenttemplates,
                            style: GoogleFonts.poppins(
                              fontSize: fontSize - 2,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentTemplates.length,
                          itemBuilder: (context, index) {
                            return recentTemplateCard(
                              context,
                              recentTemplates[index],
                              fontSize,
                              isDarkMode,
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget recentTemplateCard(
    BuildContext context,
    QuoteTemplate template,
    double fontSize,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.darkText;

    return GestureDetector(
      onTap: () => onTemplateSelected(template),
      child: Container(
        width: 150,
        height: 80,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: isDarkMode ? Colors.black26 : Colors.grey.shade300,
                blurRadius: 5)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Template image
              template.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: template.imageUrl,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print("Image loading error: $error for URL: $url");
                        return Container(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(
                            Icons.error,
                            color: theme.iconTheme.color,
                          ),
                        );
                      },
                      fit: BoxFit.cover,
                      cacheKey: "${template.id}_recent_image",
                      maxHeightDiskCache: 500,
                      maxWidthDiskCache: 500,
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

              // Optional title overlay at bottomR
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    template.title.isNotEmpty
                        ? template.title
                        : template.category.isNotEmpty
                            ? template.category
                            : context.loc.template,
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
