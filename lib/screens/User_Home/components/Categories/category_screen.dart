import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import 'package:mtquotes/screens/Templates/components/template/template_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';
import 'package:mtquotes/l10n/app_localization.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryScreen({
    Key? key,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
  }) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<QuoteTemplate> _categoryTemplates = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TemplateService _templateService = TemplateService();

  // Map to convert localized category names to database document IDs
  Map<String, String> getCategoryDbMap(BuildContext context) {
    return {
      context.loc.love: 'love',
      context.loc.life: 'life',
      context.loc.motivational: 'motivation',
      context.loc.friendship: 'friendship',
      context.loc.funny: 'funny',
      // Add all your categories here with their English database keys
    };
  }

  // Get the English database key for the current localized category name
  String getDatabaseCategoryId(BuildContext context, String localizedCategoryName) {
    final categoryMap = getCategoryDbMap(context);
    return categoryMap[localizedCategoryName] ?? localizedCategoryName.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    // We need to delay the fetch until after build to access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategoryTemplates();
    });
  }

  Future<void> _fetchCategoryTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get the English database ID for the current localized category name
      final dbCategoryId = getDatabaseCategoryId(context, widget.categoryName);

      // Now use this ID to query Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(dbCategoryId)
          .collection('templates')
          .orderBy('createdAt', descending: true)
          .get();

      List<QuoteTemplate> templates = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Extract timestamp and convert to DateTime or null
        DateTime? createdAt;
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }

        templates.add(QuoteTemplate(
          id: doc.id,
          imageUrl: data['imageURL'] ?? '',
          isPaid: data['isPaid'] ?? false,
          title: data['text'] ?? '',
          category: widget.categoryName,
          createdAt: createdAt,
          avgRating: (data['avgRatings'] ?? 0.0).toDouble(),
          ratingCount: data['ratingCount'] ?? 0,
        ));
      }

      setState(() {
        _categoryTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load templates: $e';
        _isLoading = false;
      });
      print('Error fetching category templates: $e');
    }
  }

  void _handleTemplateSelection(QuoteTemplate template) async {
    // Use the TemplateHandler to handle template selection
    TemplateHandler.handleTemplateSelection(
      context,
      template,
          (selectedTemplate) {
        // This callback is executed when access is granted
        // Navigate to the edit screen with the selected template
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditScreen(
              title: 'Edit ${widget.categoryName} Quote',
              templateImageUrl: selectedTemplate.imageUrl,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDarkMode),
          ),
        ),
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getIconColor(isDarkMode)),
      ),
      body: CustomScrollView(
        slivers: [
          // Templates Grid
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            ),
          )
              : _errorMessage.isNotEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
              : _categoryTemplates.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Text(
                'No templates available for ${widget.categoryName}',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: AppColors.getTextColor(isDarkMode),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
              : SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final template = _categoryTemplates[index];
                  return GestureDetector(
                    onTap: () => _handleTemplateSelection(template),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Template Image
                          template.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: template.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                              child: Icon(
                                Icons.error,
                                color: AppColors.getIconColor(isDarkMode),
                              ),
                            ),
                          )
                              : Container(
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColors.getIconColor(isDarkMode),
                            ),
                          ),

                          // PRO badge for paid templates
                          if (template.isPaid)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                  );
                },
                childCount: _categoryTemplates.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}