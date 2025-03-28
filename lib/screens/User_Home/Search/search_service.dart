import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

// Model to represent search results
class SearchResult {
  final String id;
  final String title;
  final String type;
  final String imageUrl;

  SearchResult({
    required this.id,
    required this.title,
    required this.type,
    required this.imageUrl,
  });
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search across multiple collections
  // Future<List<SearchResult>> searchAcrossCollections(String query) async {
  //   List<SearchResult> results = [];

  //   // Search in TOTD Collection
  //   final totdResults = await _searchTOTD(query);
  //   results.addAll(totdResults);

  //   // Search in Festivals Collection
  //   final festivalsResults = await _searchFestivals(query);
  //   results.addAll(festivalsResults);

  //   // Search in Categories Collection
  //   final categoriesResults = await _searchCategories(query);
  //   results.addAll(categoriesResults);

  //   // Search in Templates Collection
  //   final templatesResults = await _searchTemplates(query);
  //   results.addAll(templatesResults);

  //   return results;
  // }

  // Search TOTD Collection
  Future<List<SearchResult>> _searchTOTD(String query) async {
    final snapshot = await _firestore
        .collection('totd')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + 'z')
        .get();

    return snapshot.docs
        .map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['title'] ?? '',
              type: 'totd',
              imageUrl: doc.data()['imageUrl'] ?? '',
            ))
        .toList();
  }

  // Search Festivals Collection
  Future<List<SearchResult>> _searchFestivals(String query) async {
    final snapshot = await _firestore
        .collection('festivals')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .get();

    return snapshot.docs
        .map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['name'] ?? '',
              type: 'festivals',
              imageUrl: doc.data()['templates']?[0]?['imageURL'] ?? '',
            ))
        .toList();
  }

  // Search Categories Collection
  Future<List<SearchResult>> _searchCategories(String query) async {
    final snapshot = await _firestore
        .collection('categories')
        .where('__name__', isGreaterThanOrEqualTo: query)
        .where('__name__', isLessThan: query + 'z')
        .get();

    List<SearchResult> results = [];
    for (var doc in snapshot.docs) {
      // Fetch templates from subcollection
      final templatesSnapshot = await doc.reference
          .collection('templates')
          .where('title', isGreaterThanOrEqualTo: query)
          .get();

      results.addAll(templatesSnapshot.docs.map((templateDoc) => SearchResult(
            id: templateDoc.id,
            title: templateDoc.data()['title'] ?? '',
            type: 'categories',
            imageUrl: templateDoc.data()['imageURL'] ?? '',
          )));
    }
    return results;
  }

  // Search Templates Collection
  Future<List<SearchResult>> _searchTemplates(String query) async {
    final snapshot = await _firestore
        .collection('templates')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + 'z')
        .get();

    return snapshot.docs
        .map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['title'] ?? '',
              type: 'templates',
              imageUrl: doc.data()['imageUrl'] ?? '',
            ))
        .toList();
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
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported);
                  },
                )
              : Icon(Icons.image),
          title: Text(suggestion.title),
          subtitle: Text('Type: ${suggestion.type}'),
        );
      },

      onSelected: onSuggestionSelected,
    );
  }

  // Search method to fetch results across collections
Future<List<SearchResult>> searchAcrossCollections(String query) async {
  List<SearchResult> results = [];

  // Search Templates Collection
  final templatesSnapshot = await _firestore
      .collection('templates')
      .where('title', isGreaterThanOrEqualTo: query)
      .where('title', isLessThan: query + 'z')
      .get();

  results.addAll(templatesSnapshot.docs.map((doc) => SearchResult(
        id: doc.id,
        title: doc.data()['title'] ?? '',
        type: 'template',
        imageUrl: doc.data()['imageUrl'] ?? '',
      )));

  // Search Categories Collection
  final categoriesSnapshot = await _firestore.collection('categories').get();

  for (var categoryDoc in categoriesSnapshot.docs) {
    final templatesInCategorySnapshot = await categoryDoc.reference
        .collection('categories')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + 'z')
        .get();

    results.addAll(templatesInCategorySnapshot.docs.map((doc) => SearchResult(
          id: doc.id,
          title: doc.data()['title'] ?? '',
          type: 'Category: ${categoryDoc.id}',
          imageUrl: doc.data()['imageURL'] ?? '',
        )));
  }

  // Search TOTD Collection
  final totdCollections = ['morning', 'afternoon', 'evening'];
  for (var timeOfDay in totdCollections) {
    final totdDoc = await _firestore.collection('totd').doc(timeOfDay).get();
    
    // Check post1 and post2
    final posts = ['post1', 'post2'];
    posts.forEach((postKey) {
      final postData = totdDoc.data()?[postKey];
      if (postData != null && 
          (postData['title'] as String?)?.toLowerCase().contains(query.toLowerCase()) == true) {
        results.add(SearchResult(
          id: totdDoc.id,
          title: postData['title'] ?? '',
          type: 'TOTD: $timeOfDay',
          imageUrl: postData['imageUrl'] ?? '',
        ));
      }
    });
  }

  // Search Festivals Collection
  final festivalsSnapshot = await _firestore
      .collection('festivals')
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThan: query + 'z')
      .get();

  for (var festivalDoc in festivalsSnapshot.docs) {
    final festivalData = festivalDoc.data();
    
    // Add the festival itself if it matches
    results.add(SearchResult(
      id: festivalDoc.id,
      title: festivalData['name'] ?? '',
      type: 'Festival',
      imageUrl: '', // No direct image for festival
    ));

    // Search within festival's templates
    final templates = festivalData['templates'] as List? ?? [];
    templates.forEach((template) {
      if (template['id'] != null) {
        results.add(SearchResult(
          id: template['id'],
          title: festivalData['name'] ?? '',
          type: 'Festival Template',
          imageUrl: template['imageURL'] ?? '',
        ));
      }
    });
  }

  return results;
}

  // Optional: Navigation method for handling suggestion selection
//   void navigateToDetailPage(BuildContext context, SearchResult suggestion) {
//     switch (suggestion.type) {
//       case 'Template':
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TemplateDetailScreen(
//               templateId: suggestion.id,
//               title: suggestion.title,
//             ),
//           ),
//         );
//         break;
//       case String category when category.startsWith('Category:'):
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CategoryDetailScreen(
//               categoryName: category.split(': ')[1],
//               templateId: suggestion.id,
//             ),
//           ),
//         );
//         break;
//       default:
//         // Optional: show a generic detail or error page
//         break;
//     }
//   }
// }
}
