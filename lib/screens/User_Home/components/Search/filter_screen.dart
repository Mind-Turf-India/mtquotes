import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../Templates/components/template/quote_template.dart';
import '../../search_screen.dart';

class FilterScreen extends StatefulWidget {
  final TemplateFilters initialFilters;
  final Function(TemplateFilters) onApply;

  const FilterScreen({
    Key? key,
    required this.initialFilters,
    required this.onApply,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late TemplateFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: Text('Filters'),
      // ),
      // body: SingleChildScrollView(
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //
      //       // Free/Premium Filter
      //       _buildFilterSection(
      //         title: 'Free',
      //         isSelected: _filters.isPaid == false,
      //         onTap: () => setState(() => _filters = TemplateFilters(
      //           isPaid: false,
      //           minRating: _filters.minRating,
      //           language: _filters.language,
      //         )),
      //       ),
      //
      //       Divider(),
      //
      //       _buildFilterSection(
      //         title: 'Premium',
      //         isSelected: _filters.isPaid == true,
      //         onTap: () => setState(() => _filters = TemplateFilters(
      //           isPaid: true,
      //           minRating: _filters.minRating,
      //           language: _filters.language,
      //         )),
      //       ),
      //
      //       Divider(),
      //
      //       // Ratings Filter (Enhanced with stars visual)
      //       _buildRatingFilterSection(),
      //
      //       Divider(),
      //
      //       // Template Size Filter (if needed)
      //       _buildFilterSection(
      //         title: 'Template Size',
      //         onTap: () => {/* Implement size filter */},
      //       ),
      //
      //       Divider(),
      //
      //       // Language Filter
      //       _buildFilterSection(
      //         title: 'Language',
      //         subtitle: _filters.language ?? 'All languages',
      //         onTap: () => _showLanguagePicker(),
      //       ),
      //
      //       Divider(),
      //
      //       // Background Color Filter (if needed)
      //       _buildFilterSection(
      //         title: 'Background Color',
      //         onTap: () => {/* Implement color filter */},
      //       ),
      //     ],
      //   ),
      // ),
      // bottomNavigationBar: BottomAppBar(
      //   child: Padding(
      //     padding: const EdgeInsets.all(8.0),
      //     child: Row(
      //       children: [
      //         Expanded(
      //           child: OutlinedButton(
      //             onPressed: () {
      //               // Reset filters
      //               setState(() {
      //                 _filters = TemplateFilters();
      //               });
      //             },
      //             child: Text('Discard'),
      //           ),
      //         ),
      //         SizedBox(width: 8),
      //         Expanded(
      //           child: ElevatedButton(
      //             onPressed: () {
      //               widget.onApply(_filters);
      //               Navigator.pop(context);
      //             },
      //             style: ElevatedButton.styleFrom(
      //               backgroundColor: Colors.blue,
      //             ),
      //             child: Text('Apply'),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  // Widget _buildFilterSection({
  //   required String title,
  //   String? subtitle,
  //   required VoidCallback onTap,
  //   bool isSelected = false,
  // }) {
  //   return ListTile(
  //     title: Text(title),
  //     subtitle: subtitle != null ? Text(subtitle) : null,
  //     trailing: isSelected ? Icon(Icons.check, color: Colors.blue) : null,
  //     onTap: onTap,
  //   );
  // }

  // Enhanced rating filter section with visual stars indicator
  // Widget _buildRatingFilterSection() {
  //   return ListTile(
  //     title: Text('Ratings'),
  //     subtitle: Row(
  //       children: [
  //         ...List.generate(
  //           5,
  //               (index) => Icon(
  //             index < _filters.minRating ? Icons.star : Icons.star_border,
  //             color: index < _filters.minRating ? Colors.amber : Colors.grey,
  //             size: 20,
  //           ),
  //         ),
  //         SizedBox(width: 8),
  //         Text('${_filters.minRating.toInt()} stars and above'),
  //       ],
  //     ),
  //     onTap: () => _showRatingPicker(),
  //   );
  // }

  // void _showRatingPicker() {
  //   // Show a dialog to select minimum rating with improved UI
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Select Minimum Rating'),
  //       content: Container(
  //         width: double.maxFinite,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text('Show templates with at least:'),
  //             SizedBox(height: 16),
  //             // Include "All" option (0 stars)
  //             _buildRatingOption(context, 0),
  //             ...List.generate(5, (i) => _buildRatingOption(context, i + 1)),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildRatingOption(BuildContext context, int rating) {
  //   return ListTile(
  //     title: Row(
  //       children: [
  //         if (rating == 0)
  //           Text('All templates')
  //         else
  //           Row(
  //             children: [
  //               ...List.generate(
  //                 5,
  //                     (index) => Icon(
  //                   index < rating ? Icons.star : Icons.star_outline,
  //                   color: index < rating ? Colors.amber : Colors.grey,
  //                   size: 24,
  //                 ),
  //               ),
  //               SizedBox(width: 8),
  //               Text('and above'),
  //             ],
  //           ),
  //       ],
  //     ),
  //     onTap: () {
  //       setState(() {
  //         _filters = TemplateFilters(
  //           isPaid: _filters.isPaid,
  //           minRating: rating.toDouble(),
  //           language: _filters.language,
  //         );
  //       });
  //       Navigator.pop(context);
  //     },
  //     selected: _filters.minRating == rating.toDouble(),
  //     selectedTileColor: Colors.blue.withOpacity(0.1),
  //   );
  // }
  //
  // void _showLanguagePicker() {
  //   // List of supported languages
  //   final languages = ['English', 'Hindi', 'Bengali', 'Telugu', 'Gujarati', 'Marathi', 'Oridiya'];
  //   final languageCodes = ['en', 'hi', 'bn', 'te', 'gu', 'mr', 'or'];
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Select Language'),
  //       content: Container(
  //         width: double.maxFinite,
  //         child: ListView(
  //           shrinkWrap: true,
  //           children: [
  //             ListTile(
  //               title: Text('All Languages'),
  //               onTap: () {
  //                 setState(() {
  //                   _filters = TemplateFilters(
  //                     isPaid: _filters.isPaid,
  //                     minRating: _filters.minRating,
  //                     language: null,
  //                   );
  //                 });
  //                 Navigator.pop(context);
  //               },
  //               selected: _filters.language == null,
  //               selectedTileColor: Colors.blue.withOpacity(0.1),
  //             ),
  //             ...List.generate(
  //               languages.length,
  //                   (i) => ListTile(
  //                 title: Text(languages[i]),
  //                 onTap: () {
  //                   setState(() {
  //                     _filters = TemplateFilters(
  //                       isPaid: _filters.isPaid,
  //                       minRating: _filters.minRating,
  //                       language: languageCodes[i],
  //                     );
  //                   });
  //                   Navigator.pop(context);
  //                 },
  //                 selected: _filters.language == languageCodes[i],
  //                 selectedTileColor: Colors.blue.withOpacity(0.1),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}


class FilterService {
  // Use US region explicitly
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // To filter templates
  Future<List<QuoteTemplate>> filterTemplates(String searchTerm, TemplateFilters filters) async {
    print('Filtering with parameters: searchTerm=$searchTerm, filters=$filters');
    return await _localFiltering(searchTerm, filters);
  }

  // Local filtering implementation
  Future<List<QuoteTemplate>> _localFiltering(String searchTerm, TemplateFilters filters) async {
    print('Performing local filtering');
    List<QuoteTemplate> results = [];

    try {
      // 1. Filter in categories > templates collection
      if (filters.minRating > 0) {
        // If we're filtering by rating, we need to query differently in each collection
        await _filterCategoryTemplatesByRating(results, searchTerm, filters);
      } else {
        await _filterCategoryTemplates(results, searchTerm, filters);
      }

      // 2. Filter in templates collection
      if (filters.minRating > 0) {
        await _filterMainTemplatesByRating(results, searchTerm, filters);
      } else {
        await _filterMainTemplates(results, searchTerm, filters);
      }

      // Remove duplicates based on imageUrl
      final uniqueResults = <QuoteTemplate>[];
      final imageUrls = <String>{};

      for (final template in results) {
        if (template.imageUrl.isNotEmpty && !imageUrls.contains(template.imageUrl)) {
          imageUrls.add(template.imageUrl);
          uniqueResults.add(template);
        }
      }

      // Sort results by rating if rating filter is applied
      if (filters.minRating > 0) {
        uniqueResults.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      }

      print('Local filtering found ${uniqueResults.length} results');
      return uniqueResults;
    } catch (e) {
      print('Error in local filtering: $e');
      return [];
    }
  }

  // Helper method to filter category templates
  Future<void> _filterCategoryTemplates(
      List<QuoteTemplate> results, String searchTerm, TemplateFilters filters) async {
    try {
      final categoriesSnapshot = await _firestore.collection('categories').get();

      for (final categoryDoc in categoriesSnapshot.docs) {
        try {
          // Build query with applicable filters
          Query<Map<String, dynamic>> templatesQuery =
          categoryDoc.reference.collection('templates');

          // Apply isPaid filter if specified
          if (filters.isPaid != null) {
            templatesQuery = templatesQuery.where('isPaid', isEqualTo: filters.isPaid);
          }

          // Apply language filter if specified
          if (filters.language != null) {
            templatesQuery = templatesQuery.where('language', isEqualTo: filters.language);
          }

          final templatesSnapshot = await templatesQuery.get();

          for (final doc in templatesSnapshot.docs) {
            _processTemplateDoc(results, doc, categoryDoc.id, searchTerm, filters);
          }
        } catch (e) {
          print('Error processing category: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error in _filterCategoryTemplates: $e');
    }
  }

  // Helper method to filter category templates by rating
  Future<void> _filterCategoryTemplatesByRating(
      List<QuoteTemplate> results, String searchTerm, TemplateFilters filters) async {
    try {
      final categoriesSnapshot = await _firestore.collection('categories').get();

      for (final categoryDoc in categoriesSnapshot.docs) {
        try {
          // Build query with applicable filters
          Query<Map<String, dynamic>> templatesQuery =
          categoryDoc.reference.collection('templates');

          // Apply isPaid filter if specified
          if (filters.isPaid != null) {
            templatesQuery = templatesQuery.where('isPaid', isEqualTo: filters.isPaid);
          }

          // Apply language filter if specified
          if (filters.language != null) {
            templatesQuery = templatesQuery.where('language', isEqualTo: filters.language);
          }

          // Apply rating filter - try both field names
          try {
            // First try with avgRating
            final ratingQuery = templatesQuery.where(
                'avgRating', isGreaterThanOrEqualTo: filters.minRating);
            final templatesSnapshot = await ratingQuery.get();

            for (final doc in templatesSnapshot.docs) {
              _processTemplateDoc(results, doc, categoryDoc.id, searchTerm, filters);
            }
          } catch (e) {
            print('Error with avgRating query, trying avgRatings: $e');

            // If that fails, try with avgRatings
            try {
              final ratingQuery = templatesQuery.where(
                  'avgRatings', isGreaterThanOrEqualTo: filters.minRating);
              final templatesSnapshot = await ratingQuery.get();

              for (final doc in templatesSnapshot.docs) {
                _processTemplateDoc(results, doc, categoryDoc.id, searchTerm, filters);
              }
            } catch (e2) {
              print('Error with avgRatings query: $e2');
              // Get all templates and filter manually
              final templatesSnapshot = await templatesQuery.get();

              for (final doc in templatesSnapshot.docs) {
                _processTemplateDocWithRatingCheck(
                    results, doc, categoryDoc.id, searchTerm, filters);
              }
            }
          }
        } catch (e) {
          print('Error processing category: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error in _filterCategoryTemplatesByRating: $e');
    }
  }

  // Helper method to filter main templates
  Future<void> _filterMainTemplates(
      List<QuoteTemplate> results, String searchTerm, TemplateFilters filters) async {
    try {
      Query<Map<String, dynamic>> templatesQuery = _firestore.collection('templates');

      // Apply isPaid filter if specified
      if (filters.isPaid != null) {
        templatesQuery = templatesQuery.where('isPaid', isEqualTo: filters.isPaid);
      }

      // Apply language filter if specified
      if (filters.language != null) {
        templatesQuery = templatesQuery.where('language', isEqualTo: filters.language);
      }

      final templatesSnapshot = await templatesQuery.get();

      for (final doc in templatesSnapshot.docs) {
        _processMainTemplateDoc(results, doc, searchTerm, filters);
      }
    } catch (e) {
      print('Error in _filterMainTemplates: $e');
    }
  }

  // Helper method to filter main templates by rating
  Future<void> _filterMainTemplatesByRating(
      List<QuoteTemplate> results, String searchTerm, TemplateFilters filters) async {
    try {
      Query<Map<String, dynamic>> templatesQuery = _firestore.collection('templates');

      // Apply isPaid filter if specified
      if (filters.isPaid != null) {
        templatesQuery = templatesQuery.where('isPaid', isEqualTo: filters.isPaid);
      }

      // Apply language filter if specified
      if (filters.language != null) {
        templatesQuery = templatesQuery.where('language', isEqualTo: filters.language);
      }

      // Apply rating filter - try both field names
      try {
        // First try with avgRating
        final ratingQuery = templatesQuery.where(
            'avgRating', isGreaterThanOrEqualTo: filters.minRating);
        final templatesSnapshot = await ratingQuery.get();

        for (final doc in templatesSnapshot.docs) {
          _processMainTemplateDoc(results, doc, searchTerm, filters);
        }
      } catch (e) {
        print('Error with avgRating query, trying averageRating: $e');

        // If that fails, try with averageRating
        try {
          final ratingQuery = templatesQuery.where(
              'averageRating', isGreaterThanOrEqualTo: filters.minRating);
          final templatesSnapshot = await ratingQuery.get();

          for (final doc in templatesSnapshot.docs) {
            _processMainTemplateDoc(results, doc, searchTerm, filters);
          }
        } catch (e2) {
          print('Error with averageRating query: $e2');
          // Get all templates and filter manually
          final templatesSnapshot = await templatesQuery.get();

          for (final doc in templatesSnapshot.docs) {
            _processMainTemplateDocWithRatingCheck(results, doc, searchTerm, filters);
          }
        }
      }
    } catch (e) {
      print('Error in _filterMainTemplatesByRating: $e');
    }
  }

  // Process a template document from a category
  void _processTemplateDoc(List<QuoteTemplate> results,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String categoryId, String searchTerm, TemplateFilters filters) {
    try {
      final data = doc.data();

      // Safe extraction of values with null handling
      final title = data['title'] as String? ?? '';
      final isPaid = data['isPaid'] as bool? ?? false;

      // Special handling for image URL which might have different field names
      final imageUrl = (data['imageURL'] as String?) ??
          (data['imageUrl'] as String?) ?? '';

      // Extract rating - support both field names
      double rating = 0.0;
      if (data.containsKey('avgRating')) {
        rating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      } else if (data.containsKey('avgRatings')) {
        rating = (data['avgRatings'] as num?)?.toDouble() ?? 0.0;
      }

      int ratingCount = (data['ratingCount'] as int?) ?? 0;

      // Extract other fields
      final language = data['language'] as String?;

      // Apply text search filter
      if (searchTerm.isEmpty || title.toLowerCase().contains(searchTerm.toLowerCase())) {
        if (imageUrl.isNotEmpty) {
          results.add(QuoteTemplate(
            id: doc.id,
            title: title,
            imageUrl: imageUrl,
            category: categoryId,
            avgRating: rating,
            ratingCount: ratingCount,
            isPaid: isPaid,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
    } catch (e) {
      print('Error processing document: $e');
    }
  }

  // Process a template document from a category with manual rating check
  void _processTemplateDocWithRatingCheck(List<QuoteTemplate> results,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String categoryId, String searchTerm, TemplateFilters filters) {
    try {
      final data = doc.data();

      // Extract rating - support both field names
      double rating = 0.0;
      if (data.containsKey('avgRating')) {
        rating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      } else if (data.containsKey('avgRatings')) {
        rating = (data['avgRatings'] as num?)?.toDouble() ?? 0.0;
      }

      // Manual rating check
      if (rating >= filters.minRating) {
        _processTemplateDoc(results, doc, categoryId, searchTerm, filters);
      }
    } catch (e) {
      print('Error processing document with rating check: $e');
    }
  }

  // Process a template document from the main collection
  void _processMainTemplateDoc(List<QuoteTemplate> results,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String searchTerm, TemplateFilters filters) {
    try {
      final data = doc.data();

      // Safe extraction with null handling
      final title = data['title'] as String? ?? '';
      final imageUrl = data['imageUrl'] as String? ?? '';
      final category = data['category'] as String? ?? 'general';
      final isPaid = data['isPaid'] as bool? ?? false;
      final language = data['language'] as String?;

      // Extract rating - support both field names
      double rating = 0.0;
      if (data.containsKey('avgRating')) {
        rating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      } else if (data.containsKey('averageRating')) {
        rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      }

      int ratingCount = (data['ratingCount'] as int?) ?? 0;

      // Apply text search filter
      if (searchTerm.isEmpty || title.toLowerCase().contains(searchTerm.toLowerCase())) {
        if (imageUrl.isNotEmpty) {
          results.add(QuoteTemplate(
            id: doc.id,
            title: title,
            imageUrl: imageUrl,
            category: category,
            avgRating: rating,
            ratingCount: ratingCount,
            isPaid: isPaid,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
    } catch (e) {
      print('Error processing document: $e');
    }
  }

  // Process a template document from the main collection with manual rating check
  void _processMainTemplateDocWithRatingCheck(List<QuoteTemplate> results,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String searchTerm, TemplateFilters filters) {
    try {
      final data = doc.data();

      // Extract rating - support both field names
      double rating = 0.0;
      if (data.containsKey('avgRating')) {
        rating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      } else if (data.containsKey('averageRating')) {
        rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      }

      // Manual rating check
      if (rating >= filters.minRating) {
        _processMainTemplateDoc(results, doc, searchTerm, filters);
      }
    } catch (e) {
      print('Error processing document with rating check: $e');
    }
  }

  // Method to standardize rating fields across all templates
  Future<void> standardizeRatingFields() async {
    try {
      print('Starting rating field standardization');
      int updatesCount = 0;

      // 1. Standardize in categories > templates
      final categoriesSnapshot = await _firestore.collection('categories').get();
      for (final categoryDoc in categoriesSnapshot.docs) {
        try {
          final templatesSnapshot = await categoryDoc.reference.collection('templates').get();

          for (final templateDoc in templatesSnapshot.docs) {
            try {
              final data = templateDoc.data();
              bool needsUpdate = false;
              Map<String, dynamic> updateData = {};

              // Handle different possible field names
              if (data.containsKey('avgRatings') && !data.containsKey('avgRating')) {
                updateData['avgRating'] = data['avgRatings'];
                needsUpdate = true;
              } else if (data.containsKey('avgRating') && !data.containsKey('avgRatings')) {
                updateData['avgRatings'] = data['avgRating'];
                needsUpdate = true;
              }

              if (!data.containsKey('ratingCount')) {
                updateData['ratingCount'] = 0;
                needsUpdate = true;
              }

              if (needsUpdate) {
                await templateDoc.reference.update(updateData);
                updatesCount++;
              }
            } catch (e) {
              print('Error updating category template: $e');
              continue;
            }
          }
        } catch (e) {
          print('Error processing category: $e');
          continue;
        }
      }

      // 2. Standardize in templates collection
      try {
        final templatesSnapshot = await _firestore.collection('templates').get();
        for (final templateDoc in templatesSnapshot.docs) {
          try {
            final data = templateDoc.data();
            bool needsUpdate = false;
            Map<String, dynamic> updateData = {};

            // Handle different possible field names
            if (data.containsKey('averageRating') && !data.containsKey('avgRating')) {
              updateData['avgRating'] = data['averageRating'];
              needsUpdate = true;
            } else if (data.containsKey('avgRating') && !data.containsKey('averageRating')) {
              updateData['averageRating'] = data['avgRating'];
              needsUpdate = true;
            }

            if (!data.containsKey('ratingCount')) {
              updateData['ratingCount'] = 0;
              needsUpdate = true;
            }

            if (needsUpdate) {
              await templateDoc.reference.update(updateData);
              updatesCount++;
            }
          } catch (e) {
            print('Error updating main template: $e');
            continue;
          }
        }
      } catch (e) {
        print('Error querying templates collection: $e');
      }

      print('Standardized rating fields in $updatesCount templates');
    } catch (e) {
      print('Error standardizing rating fields: $e');
    }
  }
}

class TemplateModel {
  final String id;
  final String title;
  final String? imageUrl;
  final bool isPaid;
  final double avgRating;  // Changed from avgRatings to avgRating for consistency
  final int ratingCount;
  final DateTime createdAt;
  final String? language;
  final String? categoryId;
  final String collectionSource;

  TemplateModel({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.isPaid,
    required this.avgRating,
    required this.ratingCount,
    required this.createdAt,
    this.language,
    this.categoryId,
    required this.collectionSource,
  });

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    // Handle all possible rating field names
    double rating = 0.0;
    if (map.containsKey('avgRating')) {
      rating = (map['avgRating'] as num? ?? 0.0).toDouble();
    } else if (map.containsKey('avgRatings')) {
      rating = (map['avgRatings'] as num? ?? 0.0).toDouble();
    } else if (map.containsKey('averageRating')) {
      rating = (map['averageRating'] as num? ?? 0.0).toDouble();
    }

    return TemplateModel(
      id: map['id'],
      title: map['title'],
      imageUrl: map['imageUrl'] ?? map['imageURL'],
      isPaid: map['isPaid'] ?? false,
      avgRating: rating,
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      language: map['language'],
      categoryId: map['categoryId'],
      collectionSource: map['collectionSource'],
    );
  }
}