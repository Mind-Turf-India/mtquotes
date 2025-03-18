import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's subscription data
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return null;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      if (userData.containsKey('activePlan')) {
        return {
          'activePlan': userData['activePlan'],
          'isActive': userData['isActive'] ?? false,
          'subscriptionEndDate': userData['subscriptionEndDate'],
          'inTrial': userData['inTrial'] ?? false,
          'autoRenew': userData['autoRenew'] ?? false,
          'subscriptionType': userData['subscriptionType'],
          'points': userData['points'] ?? 0,
          'nextBillingDate': userData['nextBillingDate'],
          'nextBillingAmount': userData['nextBillingAmount'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting subscription: $e');
      return null;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'autoRenew': false,
      });

      // Record the cancellation event
      await _firestore.collection('subscription_events').add({
        'userId': user.uid,
        'event': 'cancel',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Check if subscription is valid
  Future<bool> isSubscriptionValid() async {
    try {
      Map<String, dynamic>? subscription = await getCurrentSubscription();
      if (subscription == null) {
        return false;
      }

      bool isActive = subscription['isActive'] ?? false;
      if (!isActive) {
        return false;
      }

      // Check if subscription is expired
      Timestamp? endDateTimestamp = subscription['subscriptionEndDate'];
      if (endDateTimestamp == null) {
        return false;
      }

      DateTime endDate = endDateTimestamp.toDate();
      return DateTime.now().isBefore(endDate);
    } catch (e) {
      print('Error checking subscription validity: $e');
      return false;
    }
  }

  // Handle subscription renewal
  Future<bool> processSubscriptionRenewal() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic>? subscription = await getCurrentSubscription();
      if (subscription == null) {
        return false;
      }

      bool autoRenew = subscription['autoRenew'] ?? false;
      if (!autoRenew) {
        return false;
      }

      Timestamp? endDateTimestamp = subscription['subscriptionEndDate'];
      if (endDateTimestamp == null) {
        return false;
      }

      DateTime endDate = endDateTimestamp.toDate();
      if (DateTime.now().isBefore(endDate)) {
        // Subscription not yet expired
        return true;
      }

      // Handle renewal logic here - this would typically be done by a backend service
      // In a real app, this would trigger a payment request or integrate with a payment gateway
      // For this example, we'll just extend the subscription period

      String subscriptionType = subscription['subscriptionType'] ?? 'monthly';
      DateTime newEndDate;

      if (subscriptionType == 'monthly') {
        newEndDate = DateTime(endDate.year, endDate.month + 1, endDate.day);
      } else if (subscriptionType == 'quarterly') {
        newEndDate = DateTime(endDate.year, endDate.month + 3, endDate.day);
      } else if (subscriptionType == 'annual') {
        newEndDate = DateTime(endDate.year + 1, endDate.month, endDate.day);
      } else {
        // Default to monthly
        newEndDate = DateTime(endDate.year, endDate.month + 1, endDate.day);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionEndDate': newEndDate,
        'lastRenewalDate': FieldValue.serverTimestamp(),
      });

      // Record the renewal event
      await _firestore.collection('subscription_events').add({
        'userId': user.uid,
        'event': 'renew',
        'subscriptionType': subscriptionType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error processing renewal: $e');
      return false;
    }
  }

  // Check if user is in trial period
  Future<bool> isInTrial() async {
    try {
      Map<String, dynamic>? subscription = await getCurrentSubscription();
      if (subscription == null) {
        return false;
      }

      bool inTrial = subscription['inTrial'] ?? false;
      if (!inTrial) {
        return false;
      }

      // Check if trial is still valid
      Timestamp? trialEndDateTimestamp = subscription['trialEndDate'];
      if (trialEndDateTimestamp == null) {
        return false;
      }

      DateTime trialEndDate = trialEndDateTimestamp.toDate();
      return DateTime.now().isBefore(trialEndDate);
    } catch (e) {
      print('Error checking trial status: $e');
      return false;
    }
  }

  // Add points to user account
  Future<bool> addPoints(int points) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(points),
      });

      // Record the points addition
      await _firestore.collection('points_events').add({
        'userId': user.uid,
        'points': points,
        'event': 'add',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding points: $e');
      return false;
    }
  }

  // Deduct points from user account
  Future<bool> usePoints(int points) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First check if user has enough points
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return false;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      int currentPoints = userData['points'] ?? 0;

      if (currentPoints < points) {
        return false; // Not enough points
      }

      await _firestore.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(-points),
      });

      // Record the points usage
      await _firestore.collection('points_events').add({
        'userId': user.uid,
        'points': points,
        'event': 'use',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error using points: $e');
      return false;
    }
  }

  // Get user points balance
  Future<int> getPointsBalance() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return 0;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      return userData['points'] ?? 0;
    } catch (e) {
      print('Error getting points balance: $e');
      return 0;
    }
  }
}