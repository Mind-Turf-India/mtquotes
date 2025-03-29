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

  @override
  void initState() {
    super.initState();
    _fetchCategoryTemplates();
  }

  Future<void> _fetchCategoryTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get templates from Firestore based on category
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryName.toLowerCase())
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
    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
      leading: GestureDetector(child: Icon(Icons.arrow_back_ios),
      onTap: () {
        Navigator.pop(context);
      },),
        title: Text(
          
          widget.categoryName,
          style: GoogleFonts.poppins(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
  
      ),
      body: CustomScrollView(
        slivers:[

          // Templates Grid
          _isLoading
              ? SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
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
                style: GoogleFonts.poppins(fontSize: fontSize),
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
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.error),
                            ),
                          )
                              : Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported),
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

                          // // Rating display
                          // if (template.ratingCount > 0)
                          //   Positioned(
                          //     bottom: 8,
                          //     right: 8,
                          //     child: Container(
                          //       padding: EdgeInsets.symmetric(
                          //         horizontal: 8,
                          //         vertical: 4,
                          //       ),
                          //       decoration: BoxDecoration(
                          //         color: Colors.black.withOpacity(0.7),
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //       child: Row(
                          //         mainAxisSize: MainAxisSize.min,
                          //         children: [
                          //           Icon(
                          //             Icons.star,
                          //             color: Colors.amber,
                          //             size: 14,
                          //           ),
                          //           SizedBox(width: 4),
                          //           Text(
                          //             template.avgRating.toStringAsFixed(1),
                          //             style: TextStyle(
                          //               color: Colors.white,
                          //               fontSize: 12,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
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