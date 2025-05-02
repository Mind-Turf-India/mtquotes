import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';

class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is subscribed
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

  // Fetch recent templates - modified to show all templates
  Future<List<QuoteTemplate>> fetchRecentTemplates() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Return all templates regardless of isPaid status
      List<QuoteTemplate> templates = snapshot.docs
          .map((doc) => QuoteTemplate.fromFirestore(doc))
          .toList();

      return templates;
    } catch (e) {
      print('Error fetching recent templates: $e');
      return [];
    }
  }

  // Fetch trending templates - modified to show all templates
  Future<List<QuoteTemplate>> fetchTrendingTemplatesByRating(double minRating) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .where('avgRating', isGreaterThanOrEqualTo: minRating)
          .orderBy('avgRating', descending: true)
          .limit(100)
          .get();

      // Return templates with rating >= minRating
      List<QuoteTemplate> templates = snapshot.docs
          .map((doc) => QuoteTemplate.fromFirestore(doc))
          .toList();

      return templates;
    } catch (e) {
      print('Error fetching trending templates by rating: $e');
      return [];
    }
  }

  // Fetch templates by category - modified to show all templates
  Future<List<QuoteTemplate>> fetchTemplatesByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      // Return all templates regardless of isPaid status
      List<QuoteTemplate> templates = snapshot.docs
          .map((doc) => QuoteTemplate.fromFirestore(doc))
          .toList();

      return templates;
    } catch (e) {
      print('Error fetching templates by category: $e');
      return [];
    }
  }

  Future<List<QuoteTemplate>> fetchTemplatesByRating(double minRating, {String? category}) async {
    try {
      Query query;

      if (category != null && category.isNotEmpty) {
        // Query from the category collection
        query = _firestore
            .collection('categories')
            .doc(category.toLowerCase())
            .collection('templates')
            .where('avgRating', isGreaterThanOrEqualTo: minRating)
            .orderBy('avgRating', descending: true);
      } else {
        // Query from the main templates collection
        query = _firestore
            .collection('templates')
            .where('avgRating', isGreaterThanOrEqualTo: minRating)
            .orderBy('avgRating', descending: true);
      }

      QuerySnapshot snapshot = await query.limit(100).get();

      List<QuoteTemplate> templates = snapshot.docs
          .map((doc) => QuoteTemplate.fromFirestore(doc))
          .toList();

      return templates;
    } catch (e) {
      print('Error fetching templates by rating: $e');
      return [];
    }
  }

  Future<List<QuoteTemplate>> filterTemplatesByRating(double minRating, {List<QuoteTemplate>? templates}) async {
    try {
      List<QuoteTemplate> result = [];

      // If templates are provided, filter them locally
      if (templates != null && templates.isNotEmpty) {
        result = templates.where((template) => template.avgRating >= minRating).toList();
        // Sort by highest rating first
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        return result;
      }

      // Otherwise, fetch from Firestore
      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .where('avgRating', isGreaterThanOrEqualTo: minRating)
          .orderBy('avgRating', descending: true)
          .limit(100)
          .get();

      result = snapshot.docs
          .map((doc) => QuoteTemplate.fromFirestore(doc))
          .toList();

      return result;
    } catch (e) {
      print('Error filtering templates by rating: $e');
      // If there's an error with Firestore query, fall back to local filtering
      if (templates != null) {
        return templates.where((template) => template.avgRating >= minRating).toList();
      }
      return [];
    }
  }


  Future<List<QuoteTemplate>> filterCategoryTemplatesByRating(
      String category, double minRating, {List<QuoteTemplate>? templates}) async {
    try {
      List<QuoteTemplate> result = [];

      // If templates are provided, filter them locally
      if (templates != null && templates.isNotEmpty) {
        result = templates.where((template) =>
        template.category.toLowerCase() == category.toLowerCase() &&
            template.avgRating >= minRating
        ).toList();

        // Sort by highest rating first
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        return result;
      }

      // Otherwise, fetch from category collection in Firestore
      final dbCategoryId = category.toLowerCase();

      QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .doc(dbCategoryId)
          .collection('templates')
          .where('avgRating', isGreaterThanOrEqualTo: minRating)
          .orderBy('avgRating', descending: true)
          .limit(100)
          .get();

      result = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract timestamp and convert to DateTime or null
        DateTime? createdAt;
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }

        // Handle different field names for rating
        double rating = 0.0;
        if (data.containsKey('avgRating')) {
          rating = (data['avgRating'] ?? 0.0).toDouble();
        } else if (data.containsKey('avgRatings')) {
          rating = (data['avgRatings'] ?? 0.0).toDouble();
        }

        return QuoteTemplate(
          id: doc.id,
          imageUrl: data['imageURL'] ?? '',
          isPaid: data['isPaid'] ?? false,
          title: data['text'] ?? '',
          category: category,
          createdAt: createdAt,
          avgRating: rating,
          ratingCount: data['ratingCount'] ?? 0,
        );
      }).toList();

      return result;
    } catch (e) {
      print('Error filtering category templates by rating: $e');
      // If there's an error with Firestore query, fall back to local filtering
      if (templates != null) {
        return templates.where((template) =>
        template.category.toLowerCase() == category.toLowerCase() &&
            template.avgRating >= minRating
        ).toList();
      }
      return [];
    }
  }

  // Update subscription status
  Future<void> updateSubscriptionStatus(bool isSubscribed) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'isSubscribed': isSubscribed});
    } catch (e) {
      print('Error updating subscription: $e');
    }
  }

  // Add a new template
  Future<void> addTemplate({
    required String imageUrl,
    required String title,
    required String category,
    required bool isPaid,
  }) async {
    try {
      await _firestore.collection('templates').add({
        'imageUrl': imageUrl,
        'title': title,
        'category': category,
        'isPaid': isPaid,
        'createdAt': FieldValue.serverTimestamp(),
        'usageCount': 0, // For tracking popularity
      });
      print('Template added successfully');
    } catch (e) {
      print('Error adding template: $e');
      throw e;
    }
  }

  // Add multiple templates at once (useful for initial setup)
  Future<void> addMultipleTemplates(List<Map<String, dynamic>> templates) async {
    try {
      final batch = _firestore.batch();

      for (var template in templates) {
        DocumentReference docRef = _firestore.collection('templates').doc();
        batch.set(docRef, {
          'imageUrl': template['imageUrl'],
          'title': template['title'],
          'category': template['category'],
          'isPaid': template['isPaid'],
          'createdAt': FieldValue.serverTimestamp(),
          'usageCount': 0, // For tracking popularity
        });
      }

      await batch.commit();
      print('${templates.length} templates added successfully');
    } catch (e) {
      print('Error adding templates: $e');
      throw e;
    }
  }
}