import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentTemplateService {
  static const int _maxRecentTemplates = 20;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get reference to the user's recent templates collection
  static DocumentReference _getUserRecentTemplatesRef() {
    final User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not logged in');
    }

    String userEmail = user.email!.replaceAll('.', '_');
    return _firestore.collection('users').doc(userEmail);
  }

  // Add a template to the user's recent templates
  static Future<void> addRecentTemplate(QuoteTemplate template) async {
    try {
      // Skip if there's no logged-in user
      if (_auth.currentUser == null) {
        print('No user logged in, cannot add recent template');
        return;
      }

      // Skip if it's a premium template and user is not premium
      bool isUserSubscribed = await isUserPremium();
      if (template.isPaid && !isUserSubscribed) {
        print('Premium template not added to recents for non-premium user');
        return;
      }

      // Get reference to user document
      final userRef = _getUserRecentTemplatesRef();

      // Get current user's data
      final userDoc = await userRef.get();

      // Create a map from the template
      Map<String, dynamic> templateMap = {
        'id': template.id,
        'title': template.title,
        'imageUrl': template.imageUrl,
        'isPaid': template.isPaid,
        'category': template.category,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': template.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      };

      // Get the current recent templates list or create an empty one
      List<Map<String, dynamic>> recentTemplates = [];

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('recentTemplates')) {
          final List<dynamic> templates = userData['recentTemplates'];
          recentTemplates = templates.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }

      // Check if the template is already in the list
      int existingIndex = recentTemplates.indexWhere((item) => item['id'] == template.id);

      // If template exists, remove it (we'll add it back at the beginning)
      if (existingIndex != -1) {
        recentTemplates.removeAt(existingIndex);
      }

      // Add the template to the beginning of the list
      recentTemplates.insert(0, templateMap);

      // Limit to max recent templates
      if (recentTemplates.length > _maxRecentTemplates) {
        recentTemplates = recentTemplates.sublist(0, _maxRecentTemplates);
      }

      // Update the user document with the new recent templates list
      await userRef.set({
        'recentTemplates': recentTemplates
      }, SetOptions(merge: true));

      print('Recent template added for user: ${template.title}');
    } catch (e) {
      print('Error adding recent template: $e');
    }
  }

  // Get all recent templates for the user
  static Future<List<QuoteTemplate>> getRecentTemplates() async {
    try {
      // Return empty list if no user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, returning empty recent templates');
        return [];
      }

      // Get reference to user document
      final userRef = _getUserRecentTemplatesRef();
      final userDoc = await userRef.get();

      List<QuoteTemplate> templates = [];

      if (!userDoc.exists) {
        return templates;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      if (!userData.containsKey('recentTemplates')) {
        return templates;
      }

      final List<dynamic> recentTemplateData = userData['recentTemplates'];
      bool isUserSubscribed = await isUserPremium();

      // Convert the list of maps to QuoteTemplate objects
      for (var templateData in recentTemplateData) {
        // Skip premium templates for non-premium users
        if (templateData['isPaid'] == true && !isUserSubscribed) {
          continue;
        }

        templates.add(QuoteTemplate(
          id: templateData['id'] ?? '',
          title: templateData['title'] ?? '',
          imageUrl: templateData['imageUrl'] ?? '',
          isPaid: templateData['isPaid'] ?? false,
          category: templateData['category'] ?? '',
          createdAt: templateData['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(templateData['createdAt'])
              : DateTime.now(),
        ));
      }

      return templates;
    } catch (e) {
      print('Error getting recent templates: $e');
      return [];
    }
  }

  // Clear all recent templates for the current user
  static Future<void> clearRecentTemplates() async {
    try {
      // Skip if no user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, cannot clear recent templates');
        return;
      }

      // Get reference to user document
      final userRef = _getUserRecentTemplatesRef();

      // Update the user document to clear the recent templates
      await userRef.update({
        'recentTemplates': []
      });

      print('Recent templates cleared for current user');
    } catch (e) {
      print('Error clearing recent templates: $e');
    }
  }

  // Check if the user is a premium user
  static Future<bool> isUserPremium() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return false;
      }

      String userEmail = user.email!.replaceAll('.', '_');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Check if user is premium based on your subscription logic
        return data['subscriptionStatus'] == 'active';
      }

      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }
}