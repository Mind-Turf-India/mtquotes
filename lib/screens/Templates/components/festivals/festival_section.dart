import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_card.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_handler.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:mtquotes/utils/shimmer.dart'; // Import the unified shimmer
import 'package:provider/provider.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../../l10n/app_localization.dart';

class FestivalSection extends StatelessWidget {
  final String title;
  final Future<List<FestivalPost>> Function() fetchFestivals;
  final Function(FestivalPost) onFestivalSelected;
  final VoidCallback? onSeeAllPressed;

  const FestivalSection({
    Key? key,
    required this.title,
    required this.fetchFestivals,
    required this.onFestivalSelected,
    this.onSeeAllPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme information
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    // Get font size from TextSizeProvider
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDarkMode),
              ),
            ),
            if (onSeeAllPressed != null)
              GestureDetector(
                onTap: onSeeAllPressed,
                child: Text(
                  context.loc.seeAll,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: FutureBuilder<List<FestivalPost>>(
            future: fetchFestivals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Use the unified shimmer component for horizontal lists
                return ShimmerHorizontalList(
                  itemCount: 5,
                  itemWidth: 100, 
                  itemHeight: 100,
                  isDarkMode: isDarkMode,
                  type: ShimmerType.festival, // Specify festival type
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    context.loc.errorLoadingFestivals,
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                      fontSize: fontSize - 2,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    context.loc.noFestivalsAvailable,
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                      fontSize: fontSize - 2,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return FestivalCard(
                    festival: snapshot.data![index],
                    fontSize: fontSize,
                    onTap: () {
                      // Use the festival handler to check access and handle selection
                      FestivalHandler.handleFestivalSelection(
                        context,
                        snapshot.data![index],
                        onFestivalSelected,
                      );
                    },
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