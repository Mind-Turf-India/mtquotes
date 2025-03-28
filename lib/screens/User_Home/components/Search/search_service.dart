import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

// Model to represent search results
class SearchResult {
  final String id;
  final String title;
  final String type;
  final String imageUrl;
  final bool isPaid;

  SearchResult({
    required this.id,
    required this.title,
    required this.type,
    required this.imageUrl,
    this.isPaid = false,
  });
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search across multiple collections
  Future<List<SearchResult>> searchAcrossCollections(String query) async {
    if (query.isEmpty) return [];

    // Normalize query for case-insensitive matching
    final normalizedQuery = query.toLowerCase().trim();

    List<SearchResult> results = [];

    try {
      // Search in Templates Collection
      final templatesResults = await _searchTemplates(normalizedQuery);
      results.addAll(templatesResults);

      // Search in Categories Collection
      final categoriesResults = await _searchCategories(normalizedQuery);
      results.addAll(categoriesResults);

      // Search in TOTD Collection
      final totdResults = await _searchTOTD(normalizedQuery);
      results.addAll(totdResults);

      // Search in Festivals Collection
      final festivalsResults = await _searchFestivals(normalizedQuery);
      results.addAll(festivalsResults);

      print('Total search results found: ${results.length}');
      return results;
    } catch (e) {
      print('Error searching across collections: $e');
      return [];
    }
  }

  // Search Templates Collection
  Future<List<SearchResult>> _searchTemplates(String query) async {
    try {
      print('Searching in templates collection...');
      final snapshot = await _firestore.collection('templates').get();

      List<SearchResult> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final category = (data['category'] as String? ?? '').toLowerCase();

        if (title.contains(query) || category.contains(query)) {
          results.add(SearchResult(
            id: doc.id,
            title: data['title'] ?? '',
            type: 'template',
            imageUrl: data['imageUrl'] ?? '',
            isPaid: data['isPaid'] ?? false,
          ));
        }
      }

      print('Found ${results.length} matching templates');
      return results;
    } catch (e) {
      print('Error searching templates: $e');
      return [];
    }
  }

  // Search Categories Collection
  Future<List<SearchResult>> _searchCategories(String query) async {
    try {
      print('Searching in categories collection...');
      final snapshot = await _firestore.collection('categories').get();

      List<SearchResult> results = [];

      for (var categoryDoc in snapshot.docs) {
        // First, add the category itself if its ID matches
        final categoryId = categoryDoc.id.toLowerCase();
        if (categoryId.contains(query)) {
          // We don't have a direct image for category, so we might use a default or the first template image
          results.add(SearchResult(
            id: categoryDoc.id,
            title: categoryDoc.id,
            type: 'category',
            imageUrl: '', // You might want to set a default image for categories
          ));
        }

        // Then search inside the templates subcollection
        try {
          final templatesSnapshot = await categoryDoc.reference
              .collection('templates')
              .get();

          for (var templateDoc in templatesSnapshot.docs) {
            final data = templateDoc.data();
            final title = data['title']?.toString().toLowerCase() ?? '';

            if (title.contains(query)) {
              results.add(SearchResult(
                id: templateDoc.id,
                title: data['title'] ?? '',
                type: 'category_template: ${categoryDoc.id}',
                imageUrl: data['imageURL'] ?? '',
                isPaid: data['isPaid'] ?? false,
              ));
            }
          }
        } catch (e) {
          print('Error searching templates in category ${categoryDoc.id}: $e');
        }
      }

      print('Found ${results.length} matching category templates');
      return results;
    } catch (e) {
      print('Error searching categories: $e');
      return [];
    }
  }

  // Search TOTD Collection
  Future<List<SearchResult>> _searchTOTD(String query) async {
    try {
      print('Searching in TOTD collection...');
      final totdCollections = ['morning', 'afternoon', 'evening'];
      List<SearchResult> results = [];

      for (var timeOfDay in totdCollections) {
        try {
          final totdDoc = await _firestore.collection('totd').doc(timeOfDay).get();

          if (!totdDoc.exists) continue;

          final data = totdDoc.data();
          if (data == null) continue;

          // Check post1 and post2
          final posts = ['post1', 'post2'];
          for (var postKey in posts) {
            if (!data.containsKey(postKey)) continue;

            final postData = data[postKey];
            if (postData == null) continue;

            final title = (postData['title'] as String? ?? '').toLowerCase();

            if (title.contains(query)) {
              results.add(SearchResult(
                id: '$timeOfDay-$postKey',
                title: postData['title'] ?? 'Quote for $timeOfDay',
                type: 'TOTD: $timeOfDay',
                imageUrl: postData['imageUrl'] ?? '',
                isPaid: postData['isPaid'] ?? false,
              ));
            }
          }
        } catch (e) {
          print('Error searching TOTD $timeOfDay: $e');
        }
      }

      print('Found ${results.length} matching TOTD items');
      return results;
    } catch (e) {
      print('Error searching TOTD collection: $e');
      return [];
    }
  }

  // Search Festivals Collection
  // Search Festivals Collection
  Future<List<SearchResult>> _searchFestivals(String query) async {
    try {
      print('Searching in festivals collection...');
      final snapshot = await _firestore.collection('festivals').get();

      List<SearchResult> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();

        if (name.contains(query)) {
          // Search within festival's templates
          final templates = data['templates'] as List<dynamic>? ?? [];
          for (var template in templates) {
            if (template is Map<String, dynamic>) {
              final imageURL = template['imageURL'] as String? ?? '';
              final isPaid = template['isPaid'] as bool? ?? false;

              // Only add the template if it has an image URL
              if (imageURL.isNotEmpty) {
                results.add(SearchResult(
                  id: '${doc.id}-template-${templates.indexOf(template)}',
                  title: data['name'] ?? '',
                  type: 'festival',
                  imageUrl: imageURL,
                  isPaid: isPaid,
                ));
              }
            }
          }
        }
      }

      print('Found ${results.length} matching festival items');
      return results;
    } catch (e) {
      print('Error searching festivals: $e');
      return [];
    }
  }

  // TypeAhead Suggestions Widget
  Widget buildSearchTypeAhead(
      BuildContext context, {
        required void Function(SearchResult) onSuggestionSelected,
        TextStyle? hintStyle,
        InputDecoration? decoration,
      }) {
    return TypeAheadField<SearchResult>(
      suggestionsCallback: (pattern) async {
        if (pattern.isEmpty) return [];
        return await searchAcrossCollections(pattern);
      },

      // Use builder method for text field configuration
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: decoration ??
              InputDecoration(
                hintText: 'Search quotes, categories, festivals...',
                hintStyle: hintStyle,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
        );
      },

      itemBuilder: (context, SearchResult suggestion) {
        return ListTile(
          leading: suggestion.imageUrl.isNotEmpty
              ? Image.network(
            suggestion.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : Icon(Icons.image),
          title: Text(suggestion.title),
          trailing: suggestion.isPaid ? Icon(Icons.lock, color: Colors.amber) : null,
        );
      },

      onSelected: onSuggestionSelected,
    );
  }
}