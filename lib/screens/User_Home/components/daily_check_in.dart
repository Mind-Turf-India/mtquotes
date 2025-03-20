import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyCheckInService {
  static const int _rewardPoints = 10;

  // Check if the user is eligible for daily check-in reward
  // This now checks Firestore instead of SharedPreferences
  static Future<bool> isEligibleForDailyReward() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('No user logged in');
        return false;
      }

      String userEmail = user.email!.replaceAll(".", "_");
      print('Checking eligibility for user: $userEmail');
      
      // Get the user document from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (!doc.exists) {
        print('User document does not exist yet - eligible for first check-in');
        return true;
      }

      // Get the last check-in timestamp
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? lastCheckIn = data['lastCheckIn'] as Timestamp?;
      
      if (lastCheckIn == null) {
        print('No previous check-in found - eligible');
        return true;
      }

      // Convert timestamp to local date
      final lastCheckInDate = DateFormat('yyyy-MM-dd').format(lastCheckIn.toDate());
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Debug prints
      print('Last check-in date from Firestore: $lastCheckInDate');
      print('Today: $today');
      print('Is eligible: ${lastCheckInDate != today}');

      // User is eligible if they've never checked in or last checked in on a different day
      return lastCheckInDate != today;
    } catch (e) {
      print('Error checking daily reward eligibility: $e');
      return false;
    }
  }

  // Process the daily check-in reward
  static Future<bool> processDailyCheckIn(BuildContext context) async {
    try {
      // Check if eligible first
      bool isEligible = await isEligibleForDailyReward();
      if (!isEligible) {
        print('User not eligible for daily reward');
        return false;
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('No user logged in');
        return false;
      }

      // Format the email for Firestore document ID
      String userEmail = user.email!.replaceAll(".", "_");
      print("Processing check-in for user: $userEmail");

      // Reference to user document
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
      
      // Use a transaction for more reliable updates
      bool success = await FirebaseFirestore.instance.runTransaction<bool>(
        (transaction) async {
          DocumentSnapshot userDoc = await transaction.get(userRef);
          
          if (!userDoc.exists) {
            // Create new document if it doesn't exist
            transaction.set(userRef, {
              'rewardPoints': _rewardPoints,
              'lastCheckIn': Timestamp.now(),  // Use explicit Timestamp for better control
              'lastCheckInDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),  // Store as string for easy comparison
              'email': user.email,
              'uid': user.uid,
              'checkInHistory': [{
                'date': Timestamp.now(),
                'points': _rewardPoints
              }]
            });
          } else {
            // Get current points value
            final data = userDoc.data() as Map<String, dynamic>;
            final currentPoints = data['rewardPoints'] ?? 0;
            
            // Get existing check-in history or create empty list
            List<dynamic> checkInHistory = data['checkInHistory'] ?? [];
            
            // Add new check-in to history
            checkInHistory.add({
              'date': Timestamp.now(),
              'points': _rewardPoints
            });
            
            // Update existing document
            transaction.update(userRef, {
              'rewardPoints': currentPoints + _rewardPoints,
              'lastCheckIn': Timestamp.now(),
              'lastCheckInDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              'checkInHistory': checkInHistory
            });
          }
          
          return true;
        },
        timeout: const Duration(seconds: 10),
      );

      if (!success) {
        print("Transaction failed");
        return false;
      }

      // Show reward popup
      if (context.mounted) {
        // Use a post-frame callback to ensure the context is fully ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRewardNotification(context);
        });
        print("Notification scheduled");
      } else {
        print("Context is no longer mounted, can't show notification");
      }

      return true;
    } catch (e) {
      print('Error processing daily check-in: $e');
      return false;
    }
  }

  // Improved notification display function
  static void _showRewardNotification(BuildContext context) {
    try {
      // First try to use a more reliable SnackBar approach
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration, color: Colors.amber),
                const SizedBox(width: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Check-in Reward!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('+$_rewardPoints points'),
                  ],
                ),
              ],
            ),
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.7,
            left: 75,
            right: 75,
          ),
        ),
      );
    } catch (e) {
      print('Error showing reward notification: $e');
      // Fallback method if the first approach fails
      try {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: const Text('Daily Check-in Reward!'),
            content: Text('You earned +$_rewardPoints points.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (dialogError) {
        print('Error showing fallback dialog: $dialogError');
      }
    }
  }

  // Function to get current user's reward points
  static Future<int> getUserRewardPoints() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print('No user logged in, returning 0 points');
        return 0;
      }

      String userEmail = user.email!.replaceAll(".", "_");
      print('Fetching points for user: $userEmail');
      
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final points = data['rewardPoints'] ?? 0;
        print('User has $points reward points');
        return points;
      } else {
        print('User document does not exist yet');
      }

      return 0;
    } catch (e) {
      print('Error getting user reward points: $e');
      return 0;
    }
  }
  
  // Function to get check-in history
  static Future<List<Map<String, dynamic>>> getCheckInHistory() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return [];
      }

      String userEmail = user.email!.replaceAll(".", "_");
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> history = data['checkInHistory'] ?? [];
        
        // Convert to List<Map<String, dynamic>>
        return history.map((item) => item as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      print('Error getting check-in history: $e');
      return [];
    }
  }
  
  // Get streak count (consecutive days checked in)
  static Future<int> getCheckInStreak() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return 0;
      }

      String userEmail = user.email!.replaceAll(".", "_");
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> history = data['checkInHistory'] ?? [];
        
        if (history.isEmpty) {
          return 0;
        }
        
        // Sort history by date
        history.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
        
        int streak = 1;
        DateTime currentDate = (history[0]['date'] as Timestamp).toDate();
        
        for (int i = 1; i < history.length; i++) {
          DateTime previousDate = (history[i]['date'] as Timestamp).toDate();
          
          // Check if dates are consecutive
          final difference = currentDate.difference(previousDate).inDays;
          if (difference == 1) {
            streak++;
            currentDate = previousDate;
          } else {
            break;
          }
        }
        
        return streak;
      }

      return 0;
    } catch (e) {
      print('Error calculating check-in streak: $e');
      return 0;
    }
  }
}