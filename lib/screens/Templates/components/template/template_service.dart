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
  Future<List<QuoteTemplate>> fetchTrendingTemplates() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .orderBy('usageCount', descending: true) // Assuming you have a field to track popularity
          .limit(100)
          .get();

      // Return all templates regardless of isPaid status
      List<QuoteTemplate> templates = snapshot.docs
          .map((doc) => QuoteTemplate.fromFirestore(doc))
          .toList();

      return templates;
    } catch (e) {
      print('Error fetching trending templates: $e');
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