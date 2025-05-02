import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';

// Define Festival model class
class Festival {
  final String id;
  final String name;
  final DateTime date;
  final int showDaysBefore;
  final DateTime createdAt;
  final List<FestivalTemplate> templates; // New field

  Festival({
    required this.id,
    required this.name,
    required this.date,
    required this.showDaysBefore,
    required this.createdAt,
    this.templates = const [],
  });

  factory Festival.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse templates
    List<FestivalTemplate> templatesList = [];
    if (data['templates'] != null) {
      for (var template in data['templates']) {
        templatesList.add(FestivalTemplate.fromMap(template));
      }
    }

    return Festival(
      id: doc.id,
      name: data['name'] ?? '',
      date: (data['festivalDate'] as Timestamp).toDate(),
      showDaysBefore: data['showDaysBefore'] ?? 7,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      templates: templatesList,
    );
  }
}

class FestivalTemplate {
  final String id;
  final String imageUrl;
  final bool isPaid;
  final double avgRating;  // Added field for template-specific rating
  final int ratingCount;   // Added field for template-specific rating count

  FestivalTemplate({
    required this.id,
    required this.imageUrl,
    this.isPaid = false,
    this.avgRating = 0.0,   // Default value
    this.ratingCount = 0,   // Default value
  });

  factory FestivalTemplate.fromMap(Map<String, dynamic> map) {
    return FestivalTemplate(
      id: map['id'] ?? '',
      imageUrl: map['imageURL'] ?? '',
      isPaid: map['isPaid'] ?? false,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: map['ratingCount'] ?? 0,
    );
  }

  // Add a toMap method for easier updates
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageURL': imageUrl,
      'isPaid': isPaid,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
    };
  }
}

class FestivalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get templates for a specific festival
  List<FestivalTemplate> getTemplatesForFestival(Festival festival) {
    return festival.templates;
  }

  // Get specific template by ID
  FestivalTemplate? getTemplateById(Festival festival, String templateId) {
    try {
      return festival.templates.firstWhere(
            (template) => template.id == templateId,
      );
    } catch (e) {
      print('Template not found: $e');
      return null;
    }
  }

  // Check if user is subscribed - updated to match TemplateService implementation
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

  // Fetch upcoming festivals
  Future<List<Festival>> fetchUpcomingFestivals() async {
    try {
      // Get current date
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .where('festivalDate', isGreaterThanOrEqualTo: startOfDay)
          .orderBy('festivalDate', descending: false)
          .limit(100)
          .get();

      List<Festival> festivals = snapshot.docs
          .map((doc) => Festival.fromFirestore(doc))
          .toList();

      return festivals;
    } catch (e) {
      print('Error fetching upcoming festivals: $e');
      return [];
    }
  }

  // Fetch recent festival posts
 Future<List<Festival>> fetchRecentFestivalPosts() async {
    try {
      // Get current date
      final DateTime now = DateTime.now();

      // Get all festivals
      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .orderBy('festivalDate')
          .get();

      // Filter festivals that should be active now
      List<Festival> festivals = [];

      for (var doc in snapshot.docs) {
        final festival = Festival.fromFirestore(doc);

        // Calculate the date when the festival should start showing
        final DateTime showFromDate = festival.date.subtract(Duration(days: festival.showDaysBefore));

        // Only include festivals that should be shown today
        if (now.isAfter(showFromDate) || now.isAtSameMomentAs(showFromDate)) {
          if (now.isBefore(festival.date.add(const Duration(days: 1)))) {
            festivals.add(festival);
          }
        }
      }

      // If no festivals are found, fetch generic posts
      if (festivals.isEmpty) {
        DocumentSnapshot genericDoc = await _firestore
            .collection('festivals')
            .doc('generic_posts')
            .get();

        if (genericDoc.exists) {
          Festival genericFestival = Festival.fromFirestore(genericDoc);
          festivals.add(genericFestival);
        }
      }

      return festivals;
    } catch (e) {
      print('Error fetching recent festivals: $e');
      return [];
    }
  }


  // Fetch trending festival posts
  Future<List<Festival>> fetchTrendingFestivalPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .limit(100)
          .get();

      List<Festival> festivals = snapshot.docs
          .map((doc) => Festival.fromFirestore(doc))
          .toList();

      return festivals;
    } catch (e) {
      print('Error fetching trending festivals: $e');
      return [];
    }
  }

  // Fetch festivals by category
  Future<List<Festival>> fetchFestivalsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      List<Festival> festivals = snapshot.docs
          .map((doc) => Festival.fromFirestore(doc))
          .toList();

      return festivals;
    } catch (e) {
      print('Error fetching festivals by category: $e');
      return [];
    }
  }

  // Get active festivals that should be shown today
  Future<List<Festival>> getActiveFestivals() async {
    try {
      final DateTime now = DateTime.now();
      final snapshot = await _firestore.collection('festivals').get();

      List<Festival> activeFestivals = [];
      for (var doc in snapshot.docs) {
        final festival = Festival.fromFirestore(doc);
        final DateTime showFromDate = festival.date.subtract(Duration(days: festival.showDaysBefore));

        // Check if today is within the active window for the festival
        if (now.isAfter(showFromDate) && now.isBefore(festival.date.add(Duration(days: 1)))) {
          activeFestivals.add(festival);
        }
      }

      return activeFestivals;
    } catch (e) {
      print('Error fetching active festivals: $e');
      return [];
    }
  }

  // Find the next upcoming festival
  Future<Festival?> getNextFestival() async {
    try {
      final DateTime now = DateTime.now();
      final snapshot = await _firestore.collection('festivals')
          .where('festivalDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('festivalDate')
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Festival.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error fetching next festival: $e');
      return null;
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


  Future<List<FestivalPost>> getTopRatedTemplates({int limit = 10, double minRating = 0.0}) async {
    try {
      List<FestivalPost> topRatedPosts = [];

      // Get all festivals
      final snapshot = await _firestore.collection('festivals').get();

      // Process each festival
      for (var doc in snapshot.docs) {
        final festival = Festival.fromFirestore(doc);

        // Process each template in the festival
        for (var template in festival.templates) {
          // Only include templates with rating above threshold
          if (template.avgRating >= minRating && template.imageUrl.isNotEmpty) {
            topRatedPosts.add(FestivalPost(
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
      }

      // Sort by rating (highest first)
      topRatedPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      // Apply limit
      if (topRatedPosts.length > limit) {
        topRatedPosts = topRatedPosts.sublist(0, limit);
      }

      return topRatedPosts;
    } catch (e) {
      print('Error getting top rated templates: $e');
      return [];
    }
  }

  // Add this method to your FestivalService class
  Future<List<FestivalPost>> filterFestivalsByRating(double minRating) async {
    try {
      List<FestivalPost> filteredPosts = [];

      // Get all festivals
      final snapshot = await _firestore.collection('festivals').get();

      // Process each festival
      for (var doc in snapshot.docs) {
        final festival = Festival.fromFirestore(doc);

        // Process each template in the festival
        for (var template in festival.templates) {
          // Only include templates with rating above threshold
          if (template.avgRating >= minRating && template.imageUrl.isNotEmpty) {
            filteredPosts.add(FestivalPost(
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
      }

      // Sort by rating (highest first)
      filteredPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      return filteredPosts;
    } catch (e) {
      print('Error filtering festivals by rating: $e');
      return [];
    }
  }

  Future<List<FestivalPost>> filterTemplatesByRating(double minRating) async {
    try {
      List<FestivalPost> filteredPosts = [];

      // Get all festivals
      final snapshot = await _firestore.collection('festivals').get();

      // Process each festival
      for (var doc in snapshot.docs) {
        final festival = Festival.fromFirestore(doc);

        // Process each template in the festival
        for (var template in festival.templates) {
          // Only include templates with rating above threshold
          if (template.avgRating >= minRating && template.imageUrl.isNotEmpty) {
            filteredPosts.add(FestivalPost(
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
      }

      // Sort by rating (highest first)
      filteredPosts.sort((a, b) => b.avgRating.compareTo(a.avgRating));

      return filteredPosts;
    } catch (e) {
      print('Error filtering templates by rating: $e');
      return [];
    }
  }

  Future<void> submitTemplateRating(String festivalId, String templateId, double rating) async {
    try {
      print('Submitting rating: $rating for template $templateId in festival $festivalId');

      // Get reference to the festival document
      final festivalRef = _firestore.collection('festivals').doc(festivalId);

      // Run this as a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Get the current festival document
        final festivalSnapshot = await transaction.get(festivalRef);

        if (!festivalSnapshot.exists) {
          print('Festival document not found: $festivalId');
          return;
        }

        // Get the templates array
        final data = festivalSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> templatesArray = data['templates'] ?? [];

        // Find the index of the template to update
        int templateIndex = -1;
        for (int i = 0; i < templatesArray.length; i++) {
          if (templatesArray[i]['id'] == templateId) {
            templateIndex = i;
            break;
          }
        }

        if (templateIndex == -1) {
          print('Template not found in festival: $templateId');
          return;
        }

        // Get the current template data
        final templateData = templatesArray[templateIndex] as Map<String, dynamic>;

        // Calculate the new average rating
        double currentAvgRating = (templateData['avgRating'] as num?)?.toDouble() ?? 0.0;
        int ratingCount = templateData['ratingCount'] ?? 0;

        int newRatingCount = ratingCount + 1;
        double newAvgRating = ((currentAvgRating * ratingCount) + rating) / newRatingCount;

        // Debug info
        print('Template $templateId - Current rating: $currentAvgRating, Count: $ratingCount');
        print('Template $templateId - New rating: $newAvgRating, Count: $newRatingCount');

        // Update the template data in the array
        templateData['avgRating'] = newAvgRating;
        templateData['ratingCount'] = newRatingCount;
        templateData['lastRated'] = FieldValue.serverTimestamp();

        // Update the templates array in the festival document
        transaction.update(festivalRef, {
          'templates': templatesArray,
        });

        print('Successfully updated rating for template $templateId in festival $festivalId');
      });
    } catch (e) {
      print('Error submitting template rating: $e');
      print('Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  // Submit rating for a festival
  Future<void> submitFestivalRating(Festival festival, double rating) async {
    try {
      final DateTime now = DateTime.now();
      User? currentUser = _auth.currentUser;

      // Create rating record
      Map<String, dynamic> ratingData = {
        'festivalId': festival.id,
        'festivalName': festival.name,
        'rating': rating,
        'createdAt': now,
        'userId': currentUser?.uid ?? 'anonymous',
        'userEmail': currentUser?.email ?? 'anonymous',
      };

      // Add to ratings collection
      await _firestore.collection('festival_ratings').add(ratingData);

      // Update average rating in the festival document
      DocumentReference festivalRef = _firestore.collection('festivals').doc(festival.id);

      // Run as transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot festivalDoc = await transaction.get(festivalRef);

        if (festivalDoc.exists) {
          Map<String, dynamic> data = festivalDoc.data() as Map<String, dynamic>;

          double currentAvgRating = data['averageRating']?.toDouble() ?? 0.0;
          int ratingCount = data['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating = ((currentAvgRating * ratingCount) + rating) / newRatingCount;

          transaction.update(festivalRef, {
            'averageRating': newAvgRating,
            'ratingCount': newRatingCount,
            'lastRated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('Rating submitted successfully for festival ${festival.name}: $rating stars');
    } catch (e) {
      print('Error submitting festival rating: $e');
      throw e;
    }
  }
}