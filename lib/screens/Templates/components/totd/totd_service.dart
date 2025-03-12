import 'package:cloud_firestore/cloud_firestore.dart';

class TimeOfDayPost {
  final String id;
  final String title;
  final String imageUrl;
  final bool isPaid;
  final double avgRating;
  final int ratingCount;
  final Timestamp createdAt;

  TimeOfDayPost({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.isPaid,
    required this.avgRating,
    required this.ratingCount,
    required this.createdAt,
  });

  factory TimeOfDayPost.fromMap(String id, Map<String, dynamic> map) {
    return TimeOfDayPost(
      id: id,
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isPaid: map['isPaid'] ?? false,
      avgRating: (map['avgRating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}

class TimeOfDayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current time of day (morning, afternoon, or evening)
  String getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  // Fetch posts for the current time of day
  Future<List<TimeOfDayPost>> fetchTimeOfDayPosts() async {
    final String timeOfDay = getCurrentTimeOfDay();
    print('Fetching posts for time of day: $timeOfDay');
    
    try {
      final DocumentSnapshot docSnapshot = await _firestore
          .collection('totd')
          .doc(timeOfDay)
          .get();

      if (!docSnapshot.exists) {
        print('No document found for $timeOfDay');
        return [];
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<TimeOfDayPost> posts = [];

      // Extract posts from the document
      data.forEach((key, value) {
        if (key.startsWith('post') && value is Map<String, dynamic>) {
          posts.add(TimeOfDayPost.fromMap(key, value));
        }
      });

      // Sort by createdAt timestamp (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('Fetched ${posts.length} posts for $timeOfDay');
      return posts;
    } catch (e) {
      print('Error fetching time of day posts: $e');
      return [];
    }
  }
}