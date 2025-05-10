import 'package:cloud_firestore/cloud_firestore.dart';

import 'components/template/quote_template.dart';

enum PostSource {
  qotd,      // Quote of the Day
  trending,  // Trending templates
  totd,      // Time of the Day
  festival,  // Festival posts
}

class UnifiedPost {
  final String id;
  final String imageUrl;
  final String title;
  final bool isPaid;
  final double rating;
  final int ratingCount;
  final Timestamp? createdAt;
  final String? category;
  final PostSource source;
  final String? userEmail;
  final String? userId;
  final String? templateId;
  final String userName;        // Add this
  final String userProfileUrl;

  UnifiedPost({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.isPaid,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.createdAt,
    this.category,
    required this.source,
    this.userEmail,
    this.userId,
    this.templateId,
    required this.userName,     // Add this
    required this.userProfileUrl,
  });

  // Create from QOTD document
// Create from QOTD document
  factory UnifiedPost.fromQOTD(String docId, Map<String, dynamic> data, {String userName = "User", String userProfileUrl = ""}) {
    return UnifiedPost(
      id: docId,
      imageUrl: data['imageURL'] ?? '',
      title: data['title'] ?? 'Quote of the Day',
      isPaid: false, // QOTD is typically free
      source: PostSource.qotd,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      userName: userName,
      userProfileUrl: userProfileUrl,
    );
  }

// Create from Trending templates
  factory UnifiedPost.fromTrending(DocumentSnapshot doc, {String userName = "User", String userProfileUrl = ""}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle different rating field names for backward compatibility
    double ratingValue = 0.0;
    if (data.containsKey('rating')) {
      ratingValue = (data['rating'] as num?)?.toDouble() ?? 0.0;
    } else if (data.containsKey('avgRating')) {
      ratingValue = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
    }

    return UnifiedPost(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      isPaid: data['isPaid'] ?? false,
      rating: ratingValue,
      ratingCount: data['ratingCount'] ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      category: data['category'],
      source: PostSource.trending,
      userEmail: data['userEmail'],
      userId: data['userId'],
      templateId: data['templateId'] ?? doc.id,
      userName: userName,
      userProfileUrl: userProfileUrl,
    );
  }

// Create from TOTD post
  factory UnifiedPost.fromTOTD(String timeOfDay, String postId, Map<String, dynamic> data, {String userName = "User", String userProfileUrl = ""}) {
    return UnifiedPost(
      id: '${timeOfDay}_$postId',
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      isPaid: data['isPaid'] ?? false,
      rating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      source: PostSource.totd,
      userName: userName,
      userProfileUrl: userProfileUrl,
    );
  }

  // Convert to QuoteTemplate for use with existing functionality
  QuoteTemplate toQuoteTemplate() {
    return QuoteTemplate(
      id: id,
      imageUrl: imageUrl,
      title: title,
      category: category ?? '',
      isPaid: isPaid,
      createdAt: createdAt != null ? (createdAt as Timestamp).toDate() : null,
      avgRating: rating,
      ratingCount: ratingCount,
    );
  }
}

