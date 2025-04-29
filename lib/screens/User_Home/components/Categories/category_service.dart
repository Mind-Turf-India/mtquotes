// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class Category {
//   final String name;
//   final String imageUrl;
//   final bool isPaid;
//   final DateTime createdAt;
//   final double avgRating;
//   final int ratingCount;
//   // final IconData icon;
//   // final Color color;
//   final String language;

//   Category({
//     required this.name,
//     required this.imageUrl,
//     required this.isPaid,
//     required this.createdAt,
//     required this.avgRating,
//     required this.ratingCount,
//     required this.icon,
//     required this.color,
//     required this.language,
//   });

//   factory Category.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     // Default icon and color mapping based on category name
//     IconData icon = Icons.format_quote;
//     Color color = Colors.blue;

//     // You can define a mapping of category names to icons and colors
//     final String categoryName = doc.id.toLowerCase();
//     if (categoryName == 'motivation') {
//       icon = Icons.lightbulb;
//       color = Colors.green;
//     } else if (categoryName == 'love') {
//       icon = Icons.favorite;
//       color = Colors.red;
//     } else if (categoryName == 'funny') {
//       icon = Icons.emoji_emotions;
//       color = Colors.orange;
//     } else if (categoryName == 'friendship') {
//       icon = Icons.people;
//       color = Colors.blue;
//     } else if (categoryName == 'life') {
//       icon = Icons.self_improvement;
//       color = Colors.purple;
//     }

//     return Category(
//       name: doc.id,
//       imageUrl: data['imageURL'] ?? '',
//       isPaid: data['isPaid'] ?? false,
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       avgRating: data['avgRatings']?.toDouble() ?? 0.0,
//       ratingCount: data['ratingCount'] ?? 0,
//       icon: icon,
//       color: color,
//       language: data['language'] ?? 'en', // Default to English if not specified
//     );
//   }
// }

// class CategoryService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Method to fetch all available categories
//   Future<List<Category>> fetchCategories() async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('categories')
//           .get();

//       return snapshot.docs
//           .map((doc) => Category.fromFirestore(doc))
//           .toList();
//     } catch (e) {
//       print('Error fetching categories: $e');
//       return [];
//     }
//   }

//    // Method to fetch categories by language
//   Future<List<Category>> fetchCategoriesByLanguage(String language) async {
//     try {
//       // First, fetch all categories
//       final QuerySnapshot snapshot = await _firestore
//           .collection('categories')
//           .get();
          
//       // Then filter by language
//       List<Category> allCategories = snapshot.docs
//           .map((doc) => Category.fromFirestore(doc))
//           .toList();
          
//       // Filter categories that have templates in the specified language
//       List<Category> filteredCategories = [];
      
//       for (var category in allCategories) {
//         // Check if this category has templates in the requested language
//         bool hasTemplatesInLanguage = await categoryHasTemplatesInLanguage(
//           category.name, 
//           language
//         );
        
//         if (hasTemplatesInLanguage) {
//           filteredCategories.add(category);
//         }
//       }
      
//       return filteredCategories;
//     } catch (e) {
//       print('Error fetching categories by language: $e');
//       return [];
//     }
//   }
  
//   // Helper method to check if a category has templates in a specific language
//   Future<bool> categoryHasTemplatesInLanguage(String categoryName, String language) async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('categories')
//           .doc(categoryName.toLowerCase())
//           .collection('templates')
//           .where('language', isEqualTo: language)
//           .limit(1)  // We only need to know if at least one exists
//           .get();
      
//       return snapshot.docs.isNotEmpty;
//     } catch (e) {
//       print('Error checking templates by language: $e');
//       return false;
//     }
//   }


//   // Method to get category details by name
//   Future<Category?> getCategoryByName(String categoryName) async {
//     try {
//       final DocumentSnapshot doc = await _firestore
//           .collection('categories')
//           .doc(categoryName.toLowerCase())
//           .get();

//       if (doc.exists) {
//         return Category.fromFirestore(doc);
//       }
//       return null;
//     } catch (e) {
//       print('Error getting category: $e');
//       return null;
//     }
//   }

//   // Method to get predefined categories if Firestore data isn't available
//   List<Map<String, dynamic>> getPredefinedCategories() {
//     return [
//       {
//         'name': 'Motivation',
//         'icon': Icons.lightbulb,
//         'color': Colors.green,
//       },
//       {
//         'name': 'Love',
//         'icon': Icons.favorite,
//         'color': Colors.red,
//       },
//       {
//         'name': 'Funny',
//         'icon': Icons.emoji_emotions,
//         'color': Colors.orange,
//       },
//       {
//         'name': 'Friendship',
//         'icon': Icons.people,
//         'color': Colors.blue,
//       },
//       {
//         'name': 'Life',
//         'icon': Icons.self_improvement,
//         'color': Colors.purple,
//       },
//     ];
//   }
//     Future<List<String>> getAvailableLanguages() async {
//     try {
//       // Query all templates across all categories to find unique languages
//       Set<String> languages = {};
      
//       // Get all categories first
//       QuerySnapshot categoriesSnapshot = await _firestore
//           .collection('categories')
//           .get();
          
//       // For each category, get templates and extract languages
//       for (var categoryDoc in categoriesSnapshot.docs) {
//         QuerySnapshot templatesSnapshot = await _firestore
//             .collection('categories')
//             .doc(categoryDoc.id)
//             .collection('templates')
//             .get();
            
//         for (var templateDoc in templatesSnapshot.docs) {
//           final data = templateDoc.data() as Map<String, dynamic>;
//           if (data.containsKey('language')) {
//             languages.add(data['language']);
//           } else {
//             // Add default language if not specified
//             languages.add('en');
//           }
//         }
//       }
      
//       return languages.toList();
//     } catch (e) {
//       print('Error fetching available languages: $e');
//       return ['en']; // Default to English if there's an error
//     }
//   }
// }