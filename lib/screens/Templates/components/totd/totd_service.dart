import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Updated TimeOfDayPost class with standardized rating fields

class TimeOfDayPost {
  final String id;
  final String title;
  final String imageUrl;
  final bool isPaid;
  final double avgRating;  // Standardized field name
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
    // Handle different rating field names for backward compatibility
    double rating = 0.0;
    if (map.containsKey('avgRating')) {
      rating = (map['avgRating'] as num?)?.toDouble() ?? 0.0;
    } else if (map.containsKey('averageRating')) {
      rating = (map['averageRating'] as num?)?.toDouble() ?? 0.0;
    }

    return TimeOfDayPost(
      id: id,
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isPaid: map['isPaid'] ?? false,
      avgRating: rating,
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  // Convert to Map for Firestore updates
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'isPaid': isPaid,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
      'createdAt': createdAt,
    };
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
  // Corrected submitRating method for TimeOfDayService
  Future<void> submitRating(TimeOfDayPost post, double rating) async {
    try {
      print('Submitting rating: $rating for TOTD post ${post.title}');

      // Extract time of day and post ID
      String timeOfDay;
      String postId;

      if (post.id.contains('_')) {
        final parts = post.id.split('_');
        timeOfDay = parts[0];
        postId = parts.length > 1 ? parts[1] : post.id; // Use first part after underscore
      } else {
        // If post ID doesn't contain underscore, assume it's directly a post ID like "post1"
        postId = post.id;

        // Try to determine time of day from context or current time
        timeOfDay = getCurrentTimeOfDay();
      }

      // Document reference for this time of day
      final DocumentReference docRef = _firestore.collection('totd').doc(timeOfDay);

      // Run as transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Get the current document
        final DocumentSnapshot docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          print('TOTD document not found for $timeOfDay');
          return;
        }

        final data = docSnapshot.data() as Map<String, dynamic>;

        // Check if post exists in the document
        if (data.containsKey(postId)) {
          final postData = data[postId] as Map<String, dynamic>;

          // Calculate the new average rating
          double currentAvgRating = postData['avgRating']?.toDouble() ?? 0.0;
          int ratingCount = postData['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating = ((currentAvgRating * ratingCount) + rating) / newRatingCount;

          // Create update data with the correct field path
          Map<String, dynamic> updateData = {
            '$postId.avgRating': newAvgRating,
            '$postId.ratingCount': newRatingCount,
            '$postId.lastRated': FieldValue.serverTimestamp(),
          };

          // Apply the update
          transaction.update(docRef, updateData);

          print('Successfully updated rating for $postId in $timeOfDay: New avgRating=$newAvgRating, Count=$newRatingCount');
        } else {
          print('Post ID $postId not found in document $timeOfDay');
        }
      });
    } catch (e) {
      print('Error submitting rating: $e');
      throw e;
    }
  }

// Corrected methods to filter TOTD posts by rating

// Fetch posts with rating above a threshold
  Future<List<TimeOfDayPost>> fetchPostsByRating(double minRating) async {
    try {
      List<TimeOfDayPost> filteredPosts = [];

      // Check each time of day
      for (String timeOfDay in ['morning', 'afternoon', 'evening']) {
        // Get the document for this time of day
        final DocumentSnapshot doc = await _firestore
            .collection('totd')
            .doc(timeOfDay)
            .get();

        if (!doc.exists) {
          print('No document found for $timeOfDay');
          continue;
        }

        final data = doc.data() as Map<String, dynamic>;

        // Process each post in the document
        data.forEach((key, value) {
          // Check if this is a post entry (typically keys like "post1", "post2")
          if (key.startsWith('post') && value is Map<String, dynamic>) {
            // Check if the post meets the rating threshold
            double postRating = (value['avgRating'] as num?)?.toDouble() ?? 0.0;

            if (postRating >= minRating) {
              // Create TimeOfDayPost with the combined ID (timeOfDay_postId)
              final combinedId = '${timeOfDay}_$key';
              filteredPosts.add(TimeOfDayPost.fromMap(combinedId, value));
            }
          }
        });
      }

      // Sort by rating (highest first)
      filteredPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      print('Found ${filteredPosts.length} posts with rating >= $minRating');
      return filteredPosts;
    } catch (e) {
      print('Error fetching posts by rating: $e');
      return [];
    }
  }

// Filter posts for a specific time period by rating
  Future<List<TimeOfDayPost>> filterPostsByTimeAndRating(String timeOfDay, double minRating) async {
    try {
      // Get the document for this time of day
      final DocumentSnapshot doc = await _firestore
          .collection('totd')
          .doc(timeOfDay)
          .get();

      if (!doc.exists) {
        print('No document found for $timeOfDay');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      List<TimeOfDayPost> filteredPosts = [];

      // Process each post in the document
      data.forEach((key, value) {
        // Check if this is a post entry
        if (key.startsWith('post') && value is Map<String, dynamic>) {
          // Check if the post meets the rating threshold
          double postRating = (value['avgRating'] as num?)?.toDouble() ?? 0.0;

          if (postRating >= minRating) {
            // Create TimeOfDayPost with the combined ID
            final combinedId = '${timeOfDay}_$key';
            filteredPosts.add(TimeOfDayPost.fromMap(combinedId, value));
          }
        }
      });

      // Sort by rating (highest first)
      filteredPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      print('Found ${filteredPosts.length} $timeOfDay posts with rating >= $minRating');
      return filteredPosts;
    } catch (e) {
      print('Error filtering posts by time and rating: $e');
      return [];
    }
  }

// Get top-rated posts across all time periods
  Future<List<TimeOfDayPost>> getTopRatedPosts(int limit) async {
    try {
      // Get all posts with any rating
      List<TimeOfDayPost> allPosts = await fetchPostsByRating(0.0);

      // Sort by rating (highest first)
      allPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      // Apply limit
      if (allPosts.length > limit && limit > 0) {
        allPosts = allPosts.sublist(0, limit);
      }

      return allPosts;
    } catch (e) {
      print('Error getting top rated posts: $e');
      return [];
    }
  }

  // Corrected method to standardize rating fields for TOTD posts

// One-time migration utility to ensure all TOTD posts have consistent rating fields
  Future<void> standardizeRatingFields() async {
    try {
      print('Starting rating field standardization for TOTD posts');
      int totalUpdates = 0;

      // Process each time of day
      for (String timeOfDay in ['morning', 'afternoon', 'evening']) {
        print('Processing $timeOfDay posts');

        // Get the document for this time of day
        final DocumentSnapshot doc = await _firestore
            .collection('totd')
            .doc(timeOfDay)
            .get();

        if (!doc.exists) {
          print('No document found for $timeOfDay, skipping');
          continue;
        }

        final data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> updateData = {};
        bool needsUpdate = false;

        // Check each post in the document
        data.forEach((key, value) {
          // Only process post entries (ignoring other fields in the document)
          if (key.startsWith('post') && value is Map<String, dynamic>) {
            bool postNeedsUpdate = false;

            // Ensure avgRating field exists
            if (!value.containsKey('avgRating')) {
              // If averageRating exists, use that value
              if (value.containsKey('averageRating')) {
                updateData['$key.avgRating'] = value['averageRating'];
              } else {
                // Otherwise set default value
                updateData['$key.avgRating'] = 0.0;
              }
              postNeedsUpdate = true;
            }

            // Ensure ratingCount field exists
            if (!value.containsKey('ratingCount')) {
              updateData['$key.ratingCount'] = 0;
              postNeedsUpdate = true;
            }

            // If post needs update, increment counter
            if (postNeedsUpdate) {
              needsUpdate = true;
              totalUpdates++;
            }
          }
        });

        // Apply updates if needed
        if (needsUpdate) {
          await _firestore
              .collection('totd')
              .doc(timeOfDay)
              .update(updateData);

          print('Updated fields for $timeOfDay document');
        } else {
          print('No updates needed for $timeOfDay document');
        }
      }

      print('Standardization complete. Updated $totalUpdates posts');
    } catch (e) {
      print('Error standardizing rating fields: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }




}