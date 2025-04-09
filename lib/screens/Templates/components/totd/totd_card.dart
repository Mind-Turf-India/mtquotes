import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_service.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';


class TimeOfDayPostComponent extends StatelessWidget {
  final TimeOfDayPost post;
  final double fontSize;
  final VoidCallback onTap;

  const TimeOfDayPostComponent({
    Key? key,
    required this.post,
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
              post.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Center(
                        // child: CircularProgressIndicator(
                        //   strokeWidth: 2,
                        //   color: theme.primaryColor,
                        // ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(
                        Icons.error, 
                        color: isDarkMode ? Colors.grey[400] : Colors.grey
                      ),
                    ),
                  )
                : Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported, 
                      color: isDarkMode ? Colors.grey[400] : Colors.grey
                    ),
                  ),
              
              // Premium badge if needed
              if (post.isPaid)
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
                
              // Optional title overlay at bottom for consistency with other components
              // Positioned(
              //   bottom: 0,
              //   left: 0,
              //   right: 0,
              //   child: Container(
              //     padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              //     color: Colors.black.withOpacity(0.5),
              //     child: Text(
              //       post.title.isNotEmpty ? post.title : "Post",
              //       style: GoogleFonts.poppins(
              //         color: Colors.white,
              //         fontSize: fontSize - 4,
              //         fontWeight: FontWeight.w500,
              //       ),
              //       overflow: TextOverflow.ellipsis,
              //       maxLines: 1,
              //       textAlign: TextAlign.center,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}