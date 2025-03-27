import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    Key? key,
    required this.recentTemplates,
    required this.onTemplateSelected,
    this.isLoading = false,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
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
              ),
            ),
            if (onViewAll != null && recentTemplates.isNotEmpty)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : !isUserLoggedIn
              ? Center(
            child: Text(
              "Sign in to view recent templates",
              style: GoogleFonts.poppins(fontSize: fontSize - 2),
            ),
          )
              : recentTemplates.isEmpty
              ? Center(
            child: Text(
              "No recent templates",
              style: GoogleFonts.poppins(fontSize: fontSize - 2),
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
      ) {
    return GestureDetector(
      onTap: () => onTemplateSelected(template),
      child: Container(
        width: 150,
        height: 80,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) {
                  print("Image loading error: $error for URL: $url");
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.error),
                  );
                },
                fit: BoxFit.cover,
                cacheKey: template.id + "_recent_image",
                maxHeightDiskCache: 500,
                maxWidthDiskCache: 500,
              )
                  : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
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

              // Optional title overlay at bottom
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