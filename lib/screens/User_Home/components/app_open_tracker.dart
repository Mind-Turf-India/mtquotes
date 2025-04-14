import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppOpenTracker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to update app open count when app is launched
  static Future<void> trackAppOpen() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        return;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");

      // Update app open count in Firestore
      await _firestore.collection('users').doc(userEmail).update({
        'appOpenCount': FieldValue.increment(1),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      print("App open tracked successfully");
    } catch (e) {
      print("Error tracking app open: $e");
    }
  }

  // Determine if we need to initialize app open fields for existing users
  static Future<void> ensureAppOpenFieldsExist() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        return;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userEmail).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Check if necessary fields exist
        bool needsUpdate = false;
        Map<String, dynamic> updateData = {};

        if (!userData.containsKey('appOpenCount')) {
          updateData['appOpenCount'] = 1; // Start with 1 for this open
          needsUpdate = true;
        }

        if (!userData.containsKey('lastAnsweredQuestionIndex')) {
          updateData['lastAnsweredQuestionIndex'] = -1; // No questions answered yet
          needsUpdate = true;
        }

        if (!userData.containsKey('lastSurveyAppOpenCount')) {
          updateData['lastSurveyAppOpenCount'] = 0;
          needsUpdate = true;
        }

        // Apply updates if needed
        if (needsUpdate) {
          await _firestore.collection('users').doc(userEmail).update(updateData);
          print("App open tracking fields initialized");
        }
      }
    } catch (e) {
      print("Error ensuring app open fields exist: $e");
    }
  }
}
