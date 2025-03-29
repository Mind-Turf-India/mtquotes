import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import 'package:mtquotes/screens/Templates/components/template/template_service.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_service.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../../providers/text_size_provider.dart';
import '../../Templates/components/festivals/festival_post.dart';

enum TemplateListType {
  trending,
  festival,  // Changed from newTemplates to just festival
  timeOfDay
}

class TemplatesListScreen extends StatefulWidget {
  final String title;
  final TemplateListType listType;
  final String? timeOfDay; // For timeOfDay type only
  final String? festivalId; // For festival type only

  const TemplatesListScreen({
    Key? key,
    required this.title,
    required this.listType,
    this.timeOfDay,
    this.festivalId,
  }) : super(key: key);

  @override
  _TemplatesListScreenState createState() => _TemplatesListScreenState();
}

class _TemplatesListScreenState extends State<TemplatesListScreen> {
  List<QuoteTemplate> _templates = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TemplateService _templateService = TemplateService();
  final FestivalService _festivalService = FestivalService(); // Add this
  final TimeOfDayService _timeOfDayService = TimeOfDayService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch different templates based on listType
      switch (widget.listType) {
        case TemplateListType.trending:
          _templates = await _templateService.fetchRecentTemplates();
          // Sort by rating for trending
          _templates.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
          break;

        case TemplateListType.festival:
        // Fetch all festival templates for the "New" section
          _templates = await _fetchAllFestivalTemplates();
          break;

        case TemplateListType.timeOfDay:
          if (widget.timeOfDay != null) {
            // Fetch templates for specific time of day
            _templates = await _fetchTimeOfDayTemplates(widget.timeOfDay!);
          }
          break;
      }

      print('Fetched ${_templates.length} templates for ${widget.listType}');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load templates: $e';
        _isLoading = false;
      });
      print('Error fetching templates: $e');
    }
  }

  Future<List<QuoteTemplate>> _fetchAllFestivalTemplates() async {
    try {
      // First, get all festivals
      final festivals = await _festivalService.fetchRecentFestivalPosts();
      List<QuoteTemplate> allTemplates = [];

      // Debug print
      print('Fetched ${festivals.length} festivals');

      // For each festival, convert to FestivalPost objects like in HomeScreen
      for (var festival in festivals) {
        try {
          // Convert to FestivalPost objects like in your HomeScreen
          List<FestivalPost> festivalPosts = FestivalPost.multipleFromFestival(festival);

          // Convert each FestivalPost to a QuoteTemplate
          for (var post in festivalPosts) {
            allTemplates.add(QuoteTemplate(
              id: post.id,
              imageUrl: post.imageUrl,
              isPaid: post.isPaid,
              title: post.name,
              category: 'Festival',
              createdAt: DateTime.now(), // Use current time if not available
              avgRating: 0.0, // Default values
              ratingCount: 0,
            ));
          }
        } catch (e) {
          print('Error processing festival ${festival.name}: $e');
        }
      }

      print('Converted ${allTemplates.length} festival posts to templates');
      return allTemplates;
    } catch (e) {
      print('Error fetching all festival templates: $e');
      return [];
    }
  }

  Future<List<QuoteTemplate>> _fetchTimeOfDayTemplates(String timeOfDay) async {
    try {
      // Using the correct collection name: totd (not timeofday)
      final DocumentSnapshot docSnapshot = await _firestore
          .collection('totd')
          .doc(timeOfDay)
          .get();

      if (!docSnapshot.exists) {
        print('No document found for $timeOfDay');
        return [];
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<QuoteTemplate> templates = [];

      // Extract posts from the document and convert to QuoteTemplate
      data.forEach((key, value) {
        if (key.startsWith('post') && value is Map<String, dynamic>) {
          // Create a TimeOfDayPost first
          final post = TimeOfDayPost.fromMap(key, value);

          // Convert to QuoteTemplate
          templates.add(QuoteTemplate(
            id: post.id,
            imageUrl: post.imageUrl,
            isPaid: post.isPaid,
            title: post.title,
            category: 'TimeOfDay',
            createdAt: post.createdAt.toDate(), // Convert Timestamp to DateTime
            avgRating: post.avgRating,
            ratingCount: post.ratingCount,
          ));
        }
      });

      // Sort by createdAt timestamp (newest first)
      templates.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      return templates;
    } catch (e) {
      print('Error fetching time of day templates: $e');
      return [];
    }
  }

  void _handleTemplateSelection(QuoteTemplate template) {
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
              title: 'Edit Template',
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
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Templates Grid
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
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
            )
                : _templates.isEmpty
                ? Center(
              child: Text(
                'No templates available',
                style: GoogleFonts.poppins(fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
            )
                : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}