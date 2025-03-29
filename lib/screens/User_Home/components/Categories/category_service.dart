import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Category {
  final String name;
  final String imageUrl;
  final bool isPaid;
  final DateTime createdAt;
  final double avgRating;
  final int ratingCount;
  final IconData icon;
  final Color color;

  Category({
    required this.name,
    required this.imageUrl,
    required this.isPaid,
    required this.createdAt,
    required this.avgRating,
    required this.ratingCount,
    required this.icon,
    required this.color,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Default icon and color mapping based on category name
    IconData icon = Icons.format_quote;
    Color color = Colors.blue;

    // You can define a mapping of category names to icons and colors
    final String categoryName = doc.id.toLowerCase();
    if (categoryName == 'motivation') {
      icon = Icons.lightbulb;
      color = Colors.green;
    } else if (categoryName == 'love') {
      icon = Icons.favorite;
      color = Colors.red;
    } else if (categoryName == 'funny') {
      icon = Icons.emoji_emotions;
      color = Colors.orange;
    } else if (categoryName == 'friendship') {
      icon = Icons.people;
      color = Colors.blue;
    } else if (categoryName == 'life') {
      icon = Icons.self_improvement;
      color = Colors.purple;
    }

    return Category(
      name: doc.id,
      imageUrl: data['imageURL'] ?? '',
      isPaid: data['isPaid'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avgRating: data['avgRatings']?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
      icon: icon,
      color: color,
    );
  }
}

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch all available categories
  Future<List<Category>> fetchCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Method to get category details by name
  Future<Category?> getCategoryByName(String categoryName) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('categories')
          .doc(categoryName.toLowerCase())
          .get();

      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  // Method to get predefined categories if Firestore data isn't available
  List<Map<String, dynamic>> getPredefinedCategories() {
    return [
      {
        'name': 'Motivation',
        'icon': Icons.lightbulb,
        'color': Colors.green,
      },
      {
        'name': 'Love',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'name': 'Funny',
        'icon': Icons.emoji_emotions,
        'color': Colors.orange,
      },
      {
        'name': 'Friendship',
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'name': 'Life',
        'icon': Icons.self_improvement,
        'color': Colors.purple,
      },
    ];
  }
}