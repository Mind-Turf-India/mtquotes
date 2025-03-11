import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteTemplate {
  final String id;
  final String imageUrl;
  final String title;
  final String category;
  final bool isPaid;
  final DateTime createdAt;
  // New fields for festival functionality
  final String? festivalId;
  final String? festivalName;

  QuoteTemplate({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.isPaid,
    required this.createdAt,
    this.festivalId,
    this.festivalName,
  });

  factory QuoteTemplate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuoteTemplate(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      isPaid: data['isPaid'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      festivalId: data['festivalId'],
      festivalName: data['festivalName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'category': category,
      'isPaid': isPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'festivalId': festivalId,
      'festivalName': festivalName,
    };
  }
}