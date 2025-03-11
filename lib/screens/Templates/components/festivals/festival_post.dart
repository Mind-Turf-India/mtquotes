import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_service.dart';

class FestivalPost {
  final String id;
  final String name;
  final String imageUrl;
  final bool isPaid;
  final DateTime createdAt;
  final String category;

  FestivalPost({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isPaid,
    required this.createdAt,
    this.category = 'General',
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
    );
  }

  // In FestivalPost class
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
          
        ));
      }
    }

    return posts;
  }

  // Add this factory method to convert Festival to FestivalPost
  factory FestivalPost.fromFestival(Festival festival) {
    // Get first template image or empty string
    String imageUrl = '';
    if (festival.templates.isNotEmpty) {
      imageUrl = festival.templates[0].imageUrl;
    }

    return FestivalPost(
      id: festival.id,
      name: festival.name,
      imageUrl: imageUrl,
      isPaid:
          festival.templates.isNotEmpty ? festival.templates[0].isPaid : false,
      createdAt: festival.createdAt,
    );
  }
}
