import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_service.dart'; // Make sure this points to your SubscriptionService class, not SubscriptionScreen

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();

  factory SubscriptionManager() {
    return _instance;
  }

  SubscriptionManager._internal();

  final SubscriptionService _subscriptionService = SubscriptionService(); // Changed from SubscriptionScreen to SubscriptionService
  Timer? _checkSubscriptionTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize subscription manager
  Future<void> initialize() async {
    // Check subscription status on app startup
    await checkSubscriptionStatus();

    // Set up periodic subscription check (every 6 hours)
    _checkSubscriptionTimer = Timer.periodic(Duration(hours: 6), (timer) async {
      await checkSubscriptionStatus();
    });
  }

  // Dispose of resources
  void dispose() {
    _checkSubscriptionTimer?.cancel();
  }

  // Check subscription status
  Future<void> checkSubscriptionStatus() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return;
      }

      // Get current subscription
      Map<String, dynamic>? subscription = await _subscriptionService.getCurrentSubscription();
      if (subscription == null) {
        return;
      }

      bool isActive = subscription['isActive'] ?? false;
      if (!isActive) {
        return;
      }

      // Check if subscription is about to expire
      Timestamp? endDateTimestamp = subscription['subscriptionEndDate'];
      if (endDateTimestamp == null) {
        return;
      }

      DateTime endDate = endDateTimestamp.toDate();
      DateTime now = DateTime.now();

      // If subscription is expired and auto-renew is on, process renewal
      if (now.isAfter(endDate)) {
        bool autoRenew = subscription['autoRenew'] ?? false;
        if (autoRenew) {
          await _subscriptionService.processSubscriptionRenewal();
        } else {
          // If auto-renew is off, mark subscription as inactive
          final String docId = user.email!.replaceAll('.', '_');
          await _firestore.collection('users').doc(docId).update({
            'isActive': false,
          });
        }
      }

      // Check if trial period is ending
      bool inTrial = subscription['inTrial'] ?? false;
      if (inTrial) {
        Timestamp? trialEndDateTimestamp = subscription['trialEndDate'];
        if (trialEndDateTimestamp != null) {
          DateTime trialEndDate = trialEndDateTimestamp.toDate();

          // If trial has ended, process the full payment
          if (now.isAfter(trialEndDate)) {
            // Update trial status
            final String docId = user.email!.replaceAll('.', '_');
            await _firestore.collection('users').doc(docId).update({
              'inTrial': false,
            });

            // In a real app, here you would trigger the full payment
            // For this example, we'll just record that the trial has ended
            await _firestore.collection('subscription_events').add({
              'userId': user.uid,
              'event': 'trial_ended',
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  // Get subscription status for UI
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    Map<String, dynamic> status = {
      'hasSubscription': false,
      'type': 'free',
      'isActive': false,
      'inTrial': false,
      'daysRemaining': 0,
      'points': 0,
    };

    try {
      Map<String, dynamic>? subscription = await _subscriptionService.getCurrentSubscription();
      if (subscription == null) {
        return status;
      }

      bool isActive = subscription['isActive'] ?? false;
      if (!isActive) {
        return status;
      }

      // Calculate days remaining
      Timestamp? endDateTimestamp = subscription['subscriptionEndDate'];
      if (endDateTimestamp == null) {
        return status;
      }

      DateTime endDate = endDateTimestamp.toDate();
      DateTime now = DateTime.now();
      int daysRemaining = endDate.difference(now).inDays;

      // Update status
      status['hasSubscription'] = true;
      status['type'] = subscription['activePlan'] ?? 'free';
      status['isActive'] = true;
      status['inTrial'] = subscription['inTrial'] ?? false;
      status['daysRemaining'] = daysRemaining;
      status['points'] = subscription['points'] ?? 0;

      return status;
    } catch (e) {
      print('Error getting subscription status: $e');
      return status;
    }
  }

  // Save local subscription cache
  Future<void> _saveLocalSubscriptionCache(Map<String, dynamic> status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_type', status['type']);
    await prefs.setBool('subscription_active', status['isActive']);
    await prefs.setBool('subscription_trial', status['inTrial']);
    await prefs.setInt('subscription_days_remaining', status['daysRemaining']);
    await prefs.setInt('subscription_points', status['points']);
  }

  // Get local subscription cache
  Future<Map<String, dynamic>> _getLocalSubscriptionCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'type': prefs.getString('subscription_type') ?? 'free',
      'isActive': prefs.getBool('subscription_active') ?? false,
      'inTrial': prefs.getBool('subscription_trial') ?? false,
      'daysRemaining': prefs.getInt('subscription_days_remaining') ?? 0,
      'points': prefs.getInt('subscription_points') ?? 0,
    };
  }
}