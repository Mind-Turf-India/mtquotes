import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteTemplate {
  final String id;
  final String imageUrl;
  final String title;
  final String category;
  final bool isPaid;
  final DateTime createdAt;

  QuoteTemplate({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.isPaid,
    required this.createdAt,
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
    );
  }
}