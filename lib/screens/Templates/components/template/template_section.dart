import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Templates/components/template/template_card.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import '../../../../utils/app_colors.dart';

class TemplateSection extends StatelessWidget {
  final String title;
  final Future<List<QuoteTemplate>> Function() fetchTemplates;
  final double fontSize;
  final Function(QuoteTemplate) onTemplateSelected;
  final bool isDarkMode;

  const TemplateSection({
    Key? key,
    required this.title,
    required this.fetchTemplates,
    required this.fontSize,
    required this.onTemplateSelected,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(isDarkMode),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: FutureBuilder<List<QuoteTemplate>>(
            future: fetchTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading templates'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No templates available'));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return TemplateCard(
                    template: snapshot.data![index],
                    fontSize: fontSize,
                    onTap: () {
                      // Use the template handler to check access and handle selection
                      TemplateHandler.handleTemplateSelection(
                        context,
                        snapshot.data![index],
                        onTemplateSelected,
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