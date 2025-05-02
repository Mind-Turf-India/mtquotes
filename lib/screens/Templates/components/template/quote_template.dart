import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteTemplate {
  final String id;
  final String imageUrl;
  final String title;
  final String category;
  final bool isPaid;
  final DateTime? createdAt;
  // New fields for festival functionality
  final String? festivalId;
  final String? festivalName;
  // Rating fields - renamed for consistency
  final double avgRating;
  final int ratingCount;
  // Add language field
  final String? language;

  QuoteTemplate({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.isPaid,
    required this.createdAt,
    this.festivalId,
    this.festivalName,
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.language, // Default to null, meaning no language specified
  });

  factory QuoteTemplate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle different rating field names for backwards compatibility
    double rating = 0.0;
    if (data.containsKey('avgRating')) {
      rating = (data['avgRating'] ?? 0.0).toDouble();
    } else if (data.containsKey('averageRating')) {
      rating = (data['averageRating'] ?? 0.0).toDouble();
    } else if (data.containsKey('avgRatings')) {
      // This is used in CategoryScreen
      rating = (data['avgRatings'] ?? 0.0).toDouble();
    }

    return QuoteTemplate(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      isPaid: data['isPaid'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      festivalId: data['festivalId'],
      festivalName: data['festivalName'],
      avgRating: rating,
      ratingCount: data['ratingCount'] ?? 0,
      language: data['language'], // Add language from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'category': category,
      'isPaid': isPaid,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'festivalId': festivalId,
      'festivalName': festivalName,
      'avgRating': avgRating,           // Updated consistent field name
      'averageRating': avgRating,       // Legacy field name for compatibility
      'ratingCount': ratingCount,
      'language': language, // Include language in Firestore document
    };
  }
}