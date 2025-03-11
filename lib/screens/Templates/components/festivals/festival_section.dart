import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_card.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_handler.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';

class FestivalSection extends StatelessWidget {
  final String title;
  final Future<List<FestivalPost>> Function() fetchFestivals;
  final double fontSize;
  final Function(FestivalPost) onFestivalSelected;
  final VoidCallback? onSeeAllPressed;

  const FestivalSection({
    Key? key,
    required this.title,
    required this.fetchFestivals,
    required this.fontSize,
    required this.onFestivalSelected,
    this.onSeeAllPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
            if (onSeeAllPressed != null)
              GestureDetector(
                onTap: onSeeAllPressed,
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: FutureBuilder<List<FestivalPost>>(
            future: fetchFestivals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading festivals'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No festivals available'));
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