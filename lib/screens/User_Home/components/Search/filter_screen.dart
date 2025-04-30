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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Filters'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar (if needed on this screen)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.mic),
                  hintText: 'Search',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Divider
            Divider(),

            // Free/Premium Filter
            _buildFilterSection(
              title: 'Free',
              isSelected: _filters.isPaid == false,
              onTap: () => setState(() => _filters = TemplateFilters(
                isPaid: false,
                minRating: _filters.minRating,
                language: _filters.language,
              )),
            ),

            Divider(),

            _buildFilterSection(
              title: 'Premium',
              isSelected: _filters.isPaid == true,
              onTap: () => setState(() => _filters = TemplateFilters(
                isPaid: true,
                minRating: _filters.minRating,
                language: _filters.language,
              )),
            ),

            Divider(),

            // Ratings Filter
            _buildFilterSection(
              title: 'Ratings',
              subtitle: '${_filters.minRating} stars and above',
              onTap: () => _showRatingPicker(),
            ),

            Divider(),

            // Template Size Filter (if needed)
            _buildFilterSection(
              title: 'Template Size',
              onTap: () => {/* Implement size filter */},
            ),

            Divider(),

            // Language Filter
            _buildFilterSection(
              title: 'Language',
              subtitle: _filters.language ?? 'All languages',
              onTap: () => _showLanguagePicker(),
            ),

            Divider(),

            // Background Color Filter (if needed)
            _buildFilterSection(
              title: 'Background Color',
              onTap: () => {/* Implement color filter */},
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Reset filters
                    setState(() {
                      _filters = TemplateFilters();
                    });
                  },
                  child: Text('Discard'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: isSelected ? Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
    );
  }

  void _showRatingPicker() {
    // Show a dialog to select minimum rating
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Minimum Rating'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 1; i <= 5; i++)
              ListTile(
                title: Row(
                  children: List.generate(
                    i,
                        (index) => Icon(Icons.star, color: Colors.amber),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _filters = TemplateFilters(
                      isPaid: _filters.isPaid,
                      minRating: i.toDouble(),
                      language: _filters.language,
                    );
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    // List of supported languages
    final languages = ['English', 'Hindi', 'Bengali', 'Telugu', 'Gujarati','Marathi','Oridiya'];
    final languageCodes = ['en', 'hi', 'bn', 'te', 'gu','mr','or'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All Languages'),
              onTap: () {
                setState(() {
                  _filters = TemplateFilters(
                    isPaid: _filters.isPaid,
                    minRating: _filters.minRating,
                    language: null,
                  );
                });
                Navigator.pop(context);
              },
            ),
            for (int i = 0; i < languages.length; i++)
              ListTile(
                title: Text(languages[i]),
                onTap: () {
                  setState(() {
                    _filters = TemplateFilters(
                      isPaid: _filters.isPaid,
                      minRating: _filters.minRating,
                      language: languageCodes[i],
                    );
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}


class FilterService {
  // Use US region explicitly
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // To filter templates
  Future<List<QuoteTemplate>> filterTemplates(String searchTerm, TemplateFilters filters) async {
    print('Filtering with parameters: searchTerm=$searchTerm, filters=$filters');

    // Skip Cloud Function attempt and use local filtering directly
    return await _localFiltering(searchTerm, filters);
  }

  // Local filtering as fallback when Cloud Function fails
  Future<List<QuoteTemplate>> _localFiltering(String searchTerm, TemplateFilters filters) async {
    print('Performing local filtering');
    List<QuoteTemplate> results = [];

    try {
      // 1. Search in categories > templates collection
      final categoriesSnapshot = await _firestore.collection('categories').get();

      for (final categoryDoc in categoriesSnapshot.docs) {
        try {
          // Build query with applicable filters
          Query<Map<String, dynamic>> templatesQuery = categoryDoc.reference.collection('templates');

          // Apply isPaid filter if specified
          if (filters.isPaid != null) {
            templatesQuery = templatesQuery.where('isPaid', isEqualTo: filters.isPaid);
          }

          // Apply rating filter if specified
          if (filters.minRating > 0) {
            templatesQuery = templatesQuery.where('avgRatings', isGreaterThanOrEqualTo: filters.minRating);
          }

          // Apply language filter if specified
          if (filters.language != null) {
            templatesQuery = templatesQuery.where('language', isEqualTo: filters.language);
          }

          final templatesSnapshot = await templatesQuery.get();

          for (final doc in templatesSnapshot.docs) {
            try {
              final data = doc.data();

              // Safe extraction of values with null handling
              final title = data['title'] as String? ?? '';
              final isPaid = data['isPaid'] as bool? ?? false;

              // Special handling for image URL which might have different field names
              final imageUrl = (data['imageURL'] as String?) ??
                  (data['imageUrl'] as String?) ?? '';

              // Handle numeric value safely
              num avgRatingsNum = 0;
              if (data['avgRatings'] != null) {
                avgRatingsNum = data['avgRatings'] as num;
              }
              final avgRatings = avgRatingsNum.toDouble();

              // Safe extraction of other fields
              final language = data['language'] as String?;

              // Apply text search filter
              if (searchTerm.isEmpty || title.toLowerCase().contains(searchTerm.toLowerCase())) {
                if (imageUrl.isNotEmpty) {
                  results.add(QuoteTemplate(
                    id: doc.id,
                    title: title,
                    imageUrl: imageUrl,
                    category: categoryDoc.id,
                    avgRating: avgRatings,
                    isPaid: isPaid,
                    createdAt: DateTime.now(),
                    language: language,
                  ));
                }
              }
            } catch (e) {
              print('Error processing document in templates subcollection: $e');
              // Continue to next document
              continue;
            }
          }
        } catch (e) {
          print('Error processing category: $e');
          // Continue to next category
          continue;
        }
      }

      // 2. Search in templates collection
      try {
        Query<Map<String, dynamic>> mainTemplatesQuery = _firestore.collection('templates');

        if (filters.isPaid != null) {
          mainTemplatesQuery = mainTemplatesQuery.where('isPaid', isEqualTo: filters.isPaid);
        }

        if (filters.minRating > 0) {
          mainTemplatesQuery = mainTemplatesQuery.where('averageRating', isGreaterThanOrEqualTo: filters.minRating);
        }

        if (filters.language != null) {
          mainTemplatesQuery = mainTemplatesQuery.where('language', isEqualTo: filters.language);
        }

        final templatesSnapshot = await mainTemplatesQuery.get();

        for (final doc in templatesSnapshot.docs) {
          try {
            final data = doc.data();

            // Safe extraction with null handling
            final title = data['title'] as String? ?? '';
            final imageUrl = data['imageUrl'] as String? ?? '';
            final category = data['category'] as String? ?? 'general';
            final isPaid = data['isPaid'] as bool? ?? false;
            final language = data['language'] as String?;

            // Handle numeric values safely
            num avgRatingNum = 0;
            if (data['averageRating'] != null) {
              avgRatingNum = data['averageRating'] as num;
            }
            final avgRating = avgRatingNum.toDouble();

            // Apply text search filter
            if (searchTerm.isEmpty || title.toLowerCase().contains(searchTerm.toLowerCase())) {
              if (imageUrl.isNotEmpty) {
                results.add(QuoteTemplate(
                  id: doc.id,
                  title: title,
                  imageUrl: imageUrl,
                  category: category,
                  avgRating: avgRating,
                  isPaid: isPaid,
                  createdAt: DateTime.now(),
                  language: language,
                ));
              }
            }
          } catch (e) {
            print('Error processing document in templates collection: $e');
            // Continue to next document
            continue;
          }
        }
      } catch (e) {
        print('Error querying templates collection: $e');
        // Continue with the results we have so far
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

      print('Local filtering found ${uniqueResults.length} results');
      return uniqueResults;
    } catch (e) {
      print('Error in local filtering: $e');
      return [];
    }
  }

  // To add language field (run once)
  Future<void> addLanguageField() async {
    try {
      // Try the Cloud Function first
      try {
        final HttpsCallable callable = _functions.httpsCallable('addLanguageField');
        final result = await callable.call({
          'defaultLanguage': 'en'
        });
        print('Language field added: ${result.data}');
      } catch (e) {
        print('Cloud Function for adding language field failed: $e');
        print('Falling back to local language field update');

        // Fallback to local update
        await _localAddLanguageField();
      }
    } catch (e) {
      print('Error adding language field: $e');
    }
  }

  // Local implementation to add language field
  Future<void> _localAddLanguageField() async {
    try {
      const defaultLanguage = 'en';
      int updates = 0;

      // Update categories > templates
      final categoriesSnapshot = await _firestore.collection('categories').get();
      for (final categoryDoc in categoriesSnapshot.docs) {
        try {
          final templatesSnapshot = await categoryDoc.reference.collection('templates').get();

          for (final templateDoc in templatesSnapshot.docs) {
            try {
              await templateDoc.reference.update({
                'language': defaultLanguage
              });
              updates++;
            } catch (e) {
              print('Error updating template document: $e');
              continue;
            }
          }
        } catch (e) {
          print('Error processing templates in category: $e');
          continue;
        }
      }

      // Update templates collection
      try {
        final templatesSnapshot = await _firestore.collection('templates').get();
        for (final templateDoc in templatesSnapshot.docs) {
          try {
            await templateDoc.reference.update({
              'language': defaultLanguage
            });
            updates++;
          } catch (e) {
            print('Error updating template in main collection: $e');
            continue;
          }
        }
      } catch (e) {
        print('Error querying templates collection: $e');
      }

      print('Updated $updates documents with language field');
    } catch (e) {
      print('Error in local language field update: $e');
    }
  }
}

class TemplateModel {
  final String id;
  final String title;
  final String? imageUrl;
  final bool isPaid;
  final double avgRatings;
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
    required this.avgRatings,
    required this.ratingCount,
    required this.createdAt,
    this.language,
    this.categoryId,
    required this.collectionSource,
  });

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    return TemplateModel(
      id: map['id'],
      title: map['title'],
      imageUrl: map['imageUrl'] ?? map['imageURL'],
      isPaid: map['isPaid'] ?? false,
      avgRatings: (map['avgRatings'] ?? map['averageRating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      language: map['language'],
      categoryId: map['categoryId'],
      collectionSource: map['collectionSource'],
    );
  }
}