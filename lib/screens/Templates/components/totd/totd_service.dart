import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Check if user is subscribed - similar to TemplateService implementation
  Future<bool> isUserSubscribed() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) return false;

      String docId = currentUser!.email!.replaceAll('.', '_');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['isPaid'] == true ||
            userData['subscriptionStatus'] == 'active';
      }
      return false;
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
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

  // Fetch posts for a specific time of day
  Future<List<TimeOfDayPost>> fetchPostsByTimeOfDay(String timeOfDay) async {
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

      // Sort by avgRating (highest first)
      posts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      print('Fetched ${posts.length} posts for $timeOfDay');
      return posts;
    } catch (e) {
      print('Error fetching time of day posts: $e');
      return [];
    }
  }

  // Fetch trending posts (highest rating across all times of day)
  Future<List<TimeOfDayPost>> fetchTrendingPosts() async {
    try {
      List<TimeOfDayPost> allPosts = [];

      // Fetch posts for all times of day
      for (String timeOfDay in ['morning', 'afternoon', 'evening']) {
        List<TimeOfDayPost> posts = await fetchPostsByTimeOfDay(timeOfDay);
        allPosts.addAll(posts);
      }

      // Sort by rating and limit to top 10
      allPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      if (allPosts.length > 10) {
        allPosts = allPosts.sublist(0, 10);
      }

      return allPosts;
    } catch (e) {
      print('Error fetching trending posts: $e');
      return [];
    }
  }

  // Get user info for the info box
  Future<Map<String, String>> getUserInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      String defaultUserName = currentUser?.displayName ?? 'User';
      String defaultProfileImageUrl = currentUser?.photoURL ?? '';

      if (currentUser?.email != null) {
        String docId = currentUser!.email!.replaceAll('.', '_');

        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(docId)
            .get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          String userName = userData['name'] != null && userData['name'].toString().isNotEmpty
              ? userData['name']
              : defaultUserName;

          String profileImageUrl = userData['profileImage'] != null && userData['profileImage'].toString().isNotEmpty
              ? userData['profileImage']
              : defaultProfileImageUrl;

          return {
            'userName': userName,
            'profileImageUrl': profileImageUrl,
          };
        }
      }

      return {
        'userName': defaultUserName,
        'profileImageUrl': defaultProfileImageUrl,
      };
    } catch (e) {
      print('Error getting user info: $e');
      return {
        'userName': 'User',
        'profileImageUrl': '',
      };
    }
  }

  // Submit rating for a post
  Future<void> submitRating(TimeOfDayPost post, double rating) async {
    try {
      final DateTime now = DateTime.now();
      User? currentUser = _auth.currentUser;

      // Create rating record
      Map<String, dynamic> ratingData = {
        'postId': post.id,
        'timeOfDay': getCurrentTimeOfDay(),
        'rating': rating,
        'createdAt': now,
        'userId': currentUser?.uid ?? 'anonymous',
        'userEmail': currentUser?.email ?? 'anonymous',
      };

      // Add to ratings collection
      await _firestore.collection('totd_ratings').add(ratingData);

      // Update average rating in the post document
      String timeOfDay = post.id.split('_')[0]; // Extract time of day from ID
      DocumentReference postRef = _firestore.collection('totd').doc(timeOfDay);

      // Run as transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postDoc = await transaction.get(postRef);

        if (postDoc.exists) {
          Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;

          if (data.containsKey(post.id)) {
            Map<String, dynamic> postData = data[post.id] as Map<String, dynamic>;

            double currentAvgRating = postData['avgRating']?.toDouble() ?? 0.0;
            int ratingCount = postData['ratingCount'] ?? 0;

            int newRatingCount = ratingCount + 1;
            double newAvgRating = ((currentAvgRating * ratingCount) + rating) / newRatingCount;

            // Update only the specific field values
            transaction.update(postRef, {
              '${post.id}.avgRating': newAvgRating,
              '${post.id}.ratingCount': newRatingCount,
              '${post.id}.lastRated': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      print('Rating submitted successfully for post ${post.id}: $rating stars');
    } catch (e) {
      print('Error submitting rating: $e');
      throw e;
    }
  }
}