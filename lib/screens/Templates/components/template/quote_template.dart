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
  // Add rating fields
  final double avgRating;
  final int ratingCount;

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
  });

  factory QuoteTemplate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
      avgRating: (data['avgRating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
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
      'avgRating': avgRating,
      'ratingCount': ratingCount,
    };
  }
}