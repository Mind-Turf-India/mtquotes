import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentTemplateService {
  static const int _maxRecentTemplates = 20;
  static const String _recentTemplatesKey = 'recent_templates';

  // Add a template to the user's recent templates
  static Future<void> addRecentTemplate(QuoteTemplate template) async {
    try {
      // Skip if it's a premium template and user is not premium
      bool isUserSubscribed = await isUserPremium();
      if (template.isPaid && !isUserSubscribed) {
        print('Premium template not added to recents for non-premium user');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Get the current recent templates
      final String? recentTemplatesJson = prefs.getString(_recentTemplatesKey);

      // Initialize recentTemplates as an empty list or from existing data
      List<Map<String, dynamic>> recentTemplates = [];

      if (recentTemplatesJson != null) {
        final List<dynamic> decoded = jsonDecode(recentTemplatesJson);
        recentTemplates = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // Check if the template is already in the list
      int existingIndex = recentTemplates.indexWhere((item) => item['id'] == template.id);

      // If template exists, remove it (we'll add it back at the beginning)
      if (existingIndex != -1) {
        recentTemplates.removeAt(existingIndex);
      }

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

      // Add the template to the beginning of the list
      recentTemplates.insert(0, templateMap);

      // Limit to max recent templates
      if (recentTemplates.length > _maxRecentTemplates) {
        recentTemplates = recentTemplates.sublist(0, _maxRecentTemplates);
      }

      // Save the updated list
      await prefs.setString(_recentTemplatesKey, jsonEncode(recentTemplates));

      print('Recent template added: ${template.title}');
    } catch (e) {
      print('Error adding recent template: $e');
    }
  }

  // Get all recent templates for the user
  static Future<List<QuoteTemplate>> getRecentTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recentTemplatesJson = prefs.getString(_recentTemplatesKey);

      List<QuoteTemplate> templates = [];

      if (recentTemplatesJson == null) {
        return templates;
      }

      final List<dynamic> recentTemplateData = jsonDecode(recentTemplatesJson);
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

  // Clear all recent templates
  static Future<void> clearRecentTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentTemplatesKey);
      print('Recent templates cleared');
    } catch (e) {
      print('Error clearing recent templates: $e');
    }
  }

  // Check if the user is a premium user
  static Future<bool> isUserPremium() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return false;
      }

      String userEmail = user.email!.replaceAll('.', '_');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Check if user is premium based on your subscription logic
        // You may need to adjust this based on your app's subscription model
        return data['subscriptionStatus'] == 'active';
      }

      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }
}