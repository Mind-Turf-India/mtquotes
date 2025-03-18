import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pay/pay.dart';
//
// class UpiApp {
//   final String name;
//   final String packageName;
//   final Uint8List icon;
//
//   UpiApp({
//     required this.name,
//     required this.packageName,
//     required this.icon,
//   });
// }

// Replace UpiPaymentHandler with PaymentHandler using pay package
class PaymentHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get payment configurations
  Map<PayProvider, PaymentConfiguration> getPaymentConfigurations({
    required String amount,
    required String planType,
    required String merchantName,
    required String merchantUpiId,
    required String transactionRefId,
  }) {
    // Google Pay configuration
    final googlePayConfig = PaymentConfiguration.fromJsonString('''
    {
      "provider": "google_pay",
      "data": {
        "environment": "TEST",
        "apiVersion": 2,
        "apiVersionMinor": 0,
        "allowedPaymentMethods": [
          {
            "type": "CARD",
            "tokenizationSpecification": {
              "type": "PAYMENT_GATEWAY",
              "parameters": {
                "gateway": "example",
                "gatewayMerchantId": "gatewayMerchantId"
              }
            },
            "parameters": {
              "allowedCardNetworks": ["VISA", "MASTERCARD"],
              "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
              "billingAddressRequired": false
            }
          }
        ],
        "merchantInfo": {
          "merchantId": "01234567890123456789",
          "merchantName": "${merchantName}"
        },
        "transactionInfo": {
          "totalPrice": "${amount}",
          "totalPriceStatus": "FINAL",
          "currencyCode": "INR",
          "countryCode": "IN"
        }
      }
    }
    ''');

    // Apple Pay configuration (add if needed)
    final applePayConfig = PaymentConfiguration.fromJsonString('''
    {
      "provider": "apple_pay",
      "data": {
        "merchantIdentifier": "merchant.com.example",
        "displayName": "${merchantName}",
        "merchantCapabilities": ["3DS", "debit", "credit"],
        "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
        "countryCode": "IN",
        "currencyCode": "INR",
        "requiredBillingContactFields": ["emailAddress", "name"],
        "requiredShippingContactFields": []
      }
    }
    ''');

    return {
      PayProvider.google_pay: googlePayConfig,
      PayProvider.apple_pay: applePayConfig,
    };
  }

  // Get payment items
  List<PaymentItem> getPaymentItems({
    required String amount,
    required String planType,
  }) {
    return [
      PaymentItem(
        amount: amount,
        label: planType,
        status: PaymentItemStatus.final_price,
      )
    ];
  }

  // Create a separate method to handle UPI payments (if needed)
  Map<String, dynamic> getUpiConfiguration({
    required String amount,
    required String planType,
    required String merchantName,
    required String merchantUpiId,
    required String transactionRefId,
  }) {
    return {
      "merchantName": merchantName,
      "merchantCode": "BCR2DN6TZBP76UNW",
      "receiverUpiId": merchantUpiId,
      "transactionNote": "Payment for $planType",
      "transactionRefId": transactionRefId,
      "amount": amount
    };
  }

  // Process payment result
  Future<Map<String, dynamic>> processPayment({
    required Map<String, dynamic> paymentResult,
    required String amount,
    required String planType,
    required bool isSubscription,
    required int trialDays,
    String? recurringType,
    String? fullAmount,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final String paymentStatus = paymentResult['status'] ?? '';
      final bool isSuccess = paymentStatus.toLowerCase() == 'success';

      if (isSuccess) {
        // Record transaction and update user data
        await _recordTransaction(
          user.uid,
          paymentResult,
          amount,
          planType,
          isSubscription,
          trialDays,
          recurringType,
          fullAmount,
        );

        return {
          'success': true,
          'message': 'Payment processed successfully',
          'transactionId': paymentResult['id'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': 'Payment failed or was canceled',
        };
      }
    } catch (e) {
      print('Error processing payment: $e');
      return {
        'success': false,
        'message': 'Error processing payment',
        'error': e.toString(),
      };
    }
  }

  // Record the transaction in Firestore
  Future<void> _recordTransaction(
      String userId,
      Map<String, dynamic> paymentResult,
      String amount,
      String planType,
      bool isSubscription,
      int trialDays,
      String? recurringType,
      String? fullAmount,
      ) async {
    try {
      final db = FirebaseFirestore.instance;

      // Create the transaction document
      Map<String, dynamic> transactionData = {
        'userId': userId,
        'transactionId': paymentResult['id'] ?? '',
        'approvalRefNo': paymentResult['approvalRefNo'] ?? '',
        'amount': double.parse(amount),
        'planType': planType,
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
        'isSubscription': isSubscription,
        'paymentMethod': paymentResult['paymentMethodType'] ?? 'unknown',
      };

      // Add subscription details if applicable
      if (isSubscription) {
        transactionData['recurringType'] = recurringType;
        transactionData['trialDays'] = trialDays;
        if (trialDays > 0 && fullAmount != null) {
          transactionData['fullAmount'] = double.parse(fullAmount);
        }
      }

      // Add transaction to Firestore
      await db.collection('transactions').add(transactionData);

      // Update user data based on transaction type
      await _updateUserData(userId, planType, isSubscription, trialDays, recurringType, fullAmount);
    } catch (e) {
      print('Error recording transaction: $e');
      throw e;
    }
  }
  // Update user data based on transaction type
  Future<void> _updateUserData(
      String userId,
      String planType,
      bool isSubscription,
      int trialDays,
      String? recurringType,
      String? fullAmount,
      ) async {
    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(userId);

      // If this is a per-template purchase, add points
      if (planType == 'Per Template') {
        await userRef.update({
          'points': FieldValue.increment(20),
        });
        return;
      }

      // If this is a subscription, update subscription details
      if (isSubscription) {
        DateTime now = DateTime.now();
        DateTime endDate;

        // Calculate subscription end date
        switch (recurringType) {
          case 'monthly':
            endDate = DateTime(now.year, now.month + 1, now.day);
            break;
          case 'quarterly':
            endDate = DateTime(now.year, now.month + 3, now.day);
            break;
          case 'yearly':
          case 'annual':
            endDate = DateTime(now.year + 1, now.month, now.day);
            break;
          default:
            endDate = DateTime(now.year, now.month + 1, now.day); // Default to monthly
        }

        // If there's a trial period, adjust start and end dates accordingly
        if (trialDays > 0) {
          DateTime trialEndDate = now.add(Duration(days: trialDays));

          await userRef.update({
            'subscription': {
              'isActive': true,
              'plan': planType,
              'startDate': now,
              'endDate': endDate,
              'isInTrial': true,
              'trialEndDate': trialEndDate,
              'recurringType': recurringType,
              'autoRenew': true,
              'fullAmount': fullAmount != null ? double.parse(fullAmount) : null,
            },
          });
        } else {
          // Regular subscription without trial
          await userRef.update({
            'subscription': {
              'isActive': true,
              'plan': planType,
              'startDate': now,
              'endDate': endDate,
              'isInTrial': false,
              'recurringType': recurringType,
              'autoRenew': true,
            },
          });
        }

        // Update feature access based on plan type
        await _updateUserFeatures(userId, planType);
      }
    } catch (e) {
      print('Error updating user data: $e');
      throw e;
    }
  }

  // Update user features based on plan type
  Future<void> _updateUserFeatures(String userId, String planType) async {
    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(userId);

      // Define feature access based on plan type
      Map<String, dynamic> features = {};

      switch (planType) {
        case 'Basic':
          features = {
            'maxTemplates': 50,
            'maxExports': 100,
            'premiumTemplates': false,
            'customBranding': false,
            'prioritySupport': false,
          };
          break;
        case 'Premium':
          features = {
            'maxTemplates': 200,
            'maxExports': 500,
            'premiumTemplates': true,
            'customBranding': false,
            'prioritySupport': true,
          };
          break;
        case 'Enterprise':
          features = {
            'maxTemplates': -1, // Unlimited
            'maxExports': -1, // Unlimited
            'premiumTemplates': true,
            'customBranding': true,
            'prioritySupport': true,
          };
          break;
        default:
        // Free tier features
          features = {
            'maxTemplates': 10,
            'maxExports': 20,
            'premiumTemplates': false,
            'customBranding': false,
            'prioritySupport': false,
          };
      }

      // Update user features
      await userRef.update({
        'features': features,
      });
    } catch (e) {
      print('Error updating user features: $e');
      throw e;
    }
  }

  // Get user's transaction history
  // Get user's transaction history
  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final db = FirebaseFirestore.instance;
      final query = await db.collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // Get subscription details for a user
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      if (userData == null || !userData.containsKey('subscription')) {
        return null;
      }

      return userData['subscription'] as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user subscription: $e');
      return null;
    }
  }

  // Cancel a subscription
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User data not found',
        };
      }

      Map<String, dynamic>? userData = userDoc.data();
      if (userData == null || !userData.containsKey('subscription')) {
        return {
          'success': false,
          'message': 'No active subscription found',
        };
      }

      await userRef.update({
        'subscription.autoRenew': false,
      });

      // Record the cancellation event
      await db.collection('subscription_events').add({
        'userId': user.uid,
        'type': 'cancellation',
        'timestamp': FieldValue.serverTimestamp(),
        'plan': userData['subscription']['plan'],
      });

      return {
        'success': true,
        'message': 'Subscription auto-renewal canceled successfully',
      };
    } catch (e) {
      print('Error canceling subscription: $e');
      return {
        'success': false,
        'message': 'Error canceling subscription',
        'error': e.toString(),
      };
    }
  }

  // Reactivate a canceled subscription
  Future<Map<String, dynamic>> reactivateSubscription() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User data not found',
        };
      }

      Map<String, dynamic>? userData = userDoc.data();
      if (userData == null || !userData.containsKey('subscription')) {
        return {
          'success': false,
          'message': 'No subscription found to reactivate',
        };
      }

      Map<String, dynamic> subscription = userData['subscription'];
      if (subscription['isActive'] == true && subscription['autoRenew'] == true) {
        return {
          'success': false,
          'message': 'Subscription is already active and set to auto-renew',
        };
      }

      await userRef.update({
        'subscription.autoRenew': true,
      });

      // Record the reactivation event
      await db.collection('subscription_events').add({
        'userId': user.uid,
        'type': 'reactivation',
        'timestamp': FieldValue.serverTimestamp(),
        'plan': subscription['plan'],
      });

      return {
        'success': true,
        'message': 'Subscription auto-renewal reactivated successfully',
      };
    } catch (e) {
      print('Error reactivating subscription: $e');
      return {
        'success': false,
        'message': 'Error reactivating subscription',
        'error': e.toString(),
      };
    }
  }

  // Upgrade subscription plan
  Future<Map<String, dynamic>> upgradeSubscription({
    required String newPlanType,
    required String amount,
    Map<String, dynamic>? paymentResult,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User data not found',
        };
      }

      // Record the upgrade transaction if payment result is provided
      if (paymentResult != null) {
        await db.collection('transactions').add({
          'userId': user.uid,
          'transactionId': paymentResult['id'] ?? '',
          'approvalRefNo': paymentResult['approvalRefNo'] ?? '',
          'amount': double.parse(amount),
          'planType': newPlanType,
          'status': 'success',
          'timestamp': FieldValue.serverTimestamp(),
          'isSubscription': true,
          'paymentMethod': paymentResult['paymentMethodType'] ?? 'unknown',
          'upgradeType': 'plan_upgrade',
        });
      }

      // Calculate new subscription end date (maintain the current one)
      DateTime now = DateTime.now();
      Map<String, dynamic>? userData = userDoc.data();
      DateTime currentEndDate = userData != null &&
          userData.containsKey('subscription') &&
          userData['subscription'].containsKey('endDate')
          ? (userData['subscription']['endDate'] as Timestamp).toDate()
          : DateTime(now.year, now.month + 1, now.day);

      // Update subscription details
      await userRef.update({
        'subscription.plan': newPlanType,
        'subscription.isActive': true,
        'subscription.autoRenew': true,
        'subscription.lastUpgrade': FieldValue.serverTimestamp(),
      });

      // Update features based on new plan
      await _updateUserFeatures(user.uid, newPlanType);

      // Record the upgrade event
      await db.collection('subscription_events').add({
        'userId': user.uid,
        'type': 'upgrade',
        'timestamp': FieldValue.serverTimestamp(),
        'previousPlan': userData != null &&
            userData.containsKey('subscription') &&
            userData['subscription'].containsKey('plan')
            ? userData['subscription']['plan']
            : 'Free',
        'newPlan': newPlanType,
      });

      return {
        'success': true,
        'message': 'Subscription upgraded successfully',
      };
    } catch (e) {
      print('Error upgrading subscription: $e');
      return {
        'success': false,
        'message': 'Error upgrading subscription',
        'error': e.toString(),
      };
    }
  }

  // Handle payment for point purchases (for per-template transactions)
  Future<Map<String, dynamic>> purchasePoints({
    required String amount,
    required int pointsToAdd,
    required Map<String, dynamic> paymentResult,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);

      // Record the transaction
      await db.collection('transactions').add({
        'userId': user.uid,
        'transactionId': paymentResult['id'] ?? '',
        'approvalRefNo': paymentResult['approvalRefNo'] ?? '',
        'amount': double.parse(amount),
        'planType': 'Point Purchase',
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
        'isSubscription': false,
        'paymentMethod': paymentResult['paymentMethodType'] ?? 'unknown',
        'pointsPurchased': pointsToAdd,
      });

      // Update user's points
      await userRef.update({
        'points': FieldValue.increment(pointsToAdd),
        'lastPointPurchase': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Points purchased successfully',
        'pointsAdded': pointsToAdd,
      };
    } catch (e) {
      print('Error purchasing points: $e');
      return {
        'success': false,
        'message': 'Error purchasing points',
        'error': e.toString(),
      };
    }
  }

  // Check if a payment is required for a specific feature
  Future<Map<String, dynamic>> checkFeatureAccess(String featureType) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'hasAccess': false,
          'message': 'User not authenticated',
          'requiresSubscription': true,
        };
      }

      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return {
          'hasAccess': false,
          'message': 'User data not found',
          'requiresSubscription': true,
        };
      }

      Map<String, dynamic>? userData = userDoc.data();
      if (userData == null) {
        return {
          'hasAccess': false,
          'message': 'User data is invalid',
          'requiresSubscription': true,
        };
      }

      // Check if user has an active subscription
      bool hasActiveSubscription = userData.containsKey('subscription') &&
          userData['subscription']['isActive'] == true;

      // Check feature access based on feature type
      switch (featureType) {
        case 'premium_template':
          if (hasActiveSubscription &&
              userData.containsKey('features') &&
              userData['features'].containsKey('premiumTemplates') &&
              userData['features']['premiumTemplates'] == true) {
            return {
              'hasAccess': true,
              'message': 'You have access to premium templates',
              'requiresSubscription': false,
            };
          } else {
            return {
              'hasAccess': false,
              'message': 'This template requires a premium subscription',
              'requiresSubscription': true,
              'recommendedPlan': 'Premium',
            };
          }

        case 'export':
        // Check if user has enough points or has a subscription that includes exports
          if (hasActiveSubscription) {
            int maxExports = userData.containsKey('features') &&
                userData['features'].containsKey('maxExports')
                ? userData['features']['maxExports']
                : 0;

            int usedExports = userData.containsKey('usedExports')
                ? userData['usedExports']
                : 0;

            if (maxExports == -1 || usedExports < maxExports) {
              return {
                'hasAccess': true,
                'message': 'You can export this template',
                'requiresSubscription': false,
              };
            } else {
              return {
                'hasAccess': false,
                'message': 'You have reached your export limit',
                'requiresSubscription': true,
                'recommendedPlan': 'Upgrade to get more exports',
              };
            }
          } else if (userData.containsKey('points') && userData['points'] >= 5) {
            return {
              'hasAccess': true,
              'message': 'You can use 5 points to export this template',
              'requiresPoints': true,
              'pointsCost': 5,
            };
          } else {
            return {
              'hasAccess': false,
              'message': 'You need more points or a subscription to export',
              'requiresSubscription': true,
              'recommendedPlan': 'Basic',
            };
          }

        default:
          return {
            'hasAccess': false,
            'message': 'Unknown feature type',
            'requiresSubscription': true,
          };
      }
    } catch (e) {
      print('Error checking feature access: $e');
      return {
        'hasAccess': false,
        'message': 'Error checking feature access',
        'error': e.toString(),
        'requiresSubscription': true,
      };
    }
  }

  // Use points for a specific action (like template export)
  Future<Map<String, dynamic>> usePoints(int pointsToUse, String actionType) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User data not found',
        };
      }

      Map<String, dynamic>? userData = userDoc.data();
      int currentPoints = userData != null && userData.containsKey('points')
          ? userData['points']
          : 0;

      if (currentPoints < pointsToUse) {
        return {
          'success': false,
          'message': 'Not enough points',
          'currentPoints': currentPoints,
          'requiredPoints': pointsToUse,
        };
      }

      // Deduct points
      await userRef.update({
        'points': FieldValue.increment(-pointsToUse),
      });

      // Record points usage
      await db.collection('point_transactions').add({
        'userId': user.uid,
        'pointsUsed': pointsToUse,
        'actionType': actionType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Points used successfully',
        'pointsUsed': pointsToUse,
        'remainingPoints': currentPoints - pointsToUse,
      };
    } catch (e) {
      print('Error using points: $e');
      return {
        'success': false,
        'message': 'Error using points',
        'error': e.toString(),
      };
    }
  }
}