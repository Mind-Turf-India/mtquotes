import 'package:cloud_firestore/cloud_firestore.dart';

import 'festival_service.dart';

class FestivalPost {
  final String id;
  final String name;
  final String imageUrl;
  final bool isPaid;
  final DateTime createdAt;
  final String category;
  final double avgRating;  // Added field
  final int ratingCount;   // Added field
  final String templateId; // Added to track which template this post is from

  FestivalPost({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isPaid,
    required this.createdAt,
    this.category = 'General',
    this.avgRating = 0.0,
    this.ratingCount = 0,
    required this.templateId,
  });

  factory FestivalPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FestivalPost(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isPaid: data['isPaid'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] ?? 'General',
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
      templateId: data['templateId'] ?? '',
    );
  }

  // Update the static method to include rating info
  static List<FestivalPost> multipleFromFestival(Festival festival) {
    List<FestivalPost> posts = [];

    for (var template in festival.templates) {
      // Only add posts with actual image URLs
      if (template.imageUrl.isNotEmpty) {
        posts.add(FestivalPost(
          id: '${festival.id}_${template.id}',
          name: festival.name,
          imageUrl: template.imageUrl,
          isPaid: template.isPaid,
          createdAt: festival.createdAt,
          category: festival.id == 'generic_posts' ? 'Generic' : 'Festival',
          avgRating: template.avgRating,
          ratingCount: template.ratingCount,
          templateId: template.id,
        ));
      }
    }

    return posts;
  }

  // Update this factory method to include rating info
  factory FestivalPost.fromFestival(Festival festival) {
    // Get first template image or empty string
    String imageUrl = '';
    double avgRating = 0.0;
    int ratingCount = 0;
    String templateId = '';

    if (festival.templates.isNotEmpty) {
      imageUrl = festival.templates[0].imageUrl;
      avgRating = festival.templates[0].avgRating;
      ratingCount = festival.templates[0].ratingCount;
      templateId = festival.templates[0].id;
    }

    return FestivalPost(
      id: festival.id,
      name: festival.name,
      imageUrl: imageUrl,
      isPaid: festival.templates.isNotEmpty ? festival.templates[0].isPaid : false,
      createdAt: festival.createdAt,
      avgRating: avgRating,
      ratingCount: ratingCount,
      templateId: templateId,
    );
  }
}
