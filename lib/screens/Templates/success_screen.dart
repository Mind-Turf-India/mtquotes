import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import '../User_Home/components/navbar_mainscreen.dart';

class SuccessScreen extends StatefulWidget {
  final String transactionId;
  final String planType;
  final String amount;
  final bool isSubscription;

  const SuccessScreen({
    Key? key,
    required this.transactionId,
    required this.planType,
    required this.amount,
    required this.isSubscription,
  }) : super(key: key);

  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool _isVerifying = true;
  bool _isSuccess = false;
  String _statusMessage = 'Verifying payment...';
  late StreamSubscription<DocumentSnapshot> _subscription;
  late FirebaseFirestore _firestore;
  int _timeoutSeconds = 120; // 2 minutes timeout
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _startPaymentVerification();
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _timer = Timer(Duration(seconds: _timeoutSeconds), () {
      // If still verifying after timeout period, update the UI
      if (_isVerifying) {
        setState(() {
          _isVerifying = false;
          _isSuccess = false;
          _statusMessage = 'Payment verification timeout. Please check your payment status in "My Subscriptions" later.';
        });
        _subscription.cancel();
      }
    });
  }

  void _startPaymentVerification() {
    // Listen to changes in the payment document
    _subscription = _firestore
        .collection('payments')
        .doc(widget.transactionId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'];
        print("payment verify");

        if (status == 'success') {
          setState(() {
            _isVerifying = false;
            _isSuccess = true;
            _statusMessage = 'Payment successful!';
          });
          _timer.cancel();
          _updateUserSubscription();
        } else if (status == 'failed') {
          setState(() {
            _isVerifying = false;
            _isSuccess = false;
            _statusMessage = 'Payment failed. Please try again.';
          });
          _timer.cancel();
        }
      }
    }, onError: (error) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = 'Error verifying payment: $error';
      });
      _timer.cancel();
    });
  }

  Future<void> _updateUserSubscription() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Replace dots with underscores in email to use as document ID
        final String docId = user.email!.replaceAll('.', '_');

        await _firestore.collection('users').doc(docId).update({
          'subscriptionStatus': 'active',
        });
      }
    } catch (e) {
      print('Error updating user subscription: $e');
    }
  }

  void _manualVerifyPayment() {
    // Manually update transaction status for demo/testing purposes
    // In production, this would be handled by a webhook/callback from the payment gateway
    _firestore.collection('payments').doc(widget.transactionId).update({
      'status': 'success',
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during verification
        return !_isVerifying;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Payment Status'),
          automaticallyImplyLeading: !_isVerifying,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation
                _isVerifying
                    ? Lottie.asset(
                  'assets/animations/payment_processing.json',
                  width: 200,
                  height: 200,
                  repeat: true,
                )
                    : Lottie.asset(
                  _isSuccess
                      ? 'assets/animations/payment_success.json'
                      : 'assets/animations/payment_failed.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                SizedBox(height: 24),

                // Status message
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isVerifying
                        ? Colors.blue
                        : (_isSuccess ? Colors.green : Colors.red),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Transaction details
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildDetailRow('Plan', widget.planType),
                        _buildDetailRow('Amount', '₹${widget.amount}'),
                        _buildDetailRow('Transaction ID', widget.transactionId),
                        _buildDetailRow(
                          'Type',
                          widget.isSubscription ? 'Subscription' : 'One-time',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Button
                if (!_isVerifying)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSuccess ? Colors.green : Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isSuccess ? 'Continue to App' : 'Back to Plans',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // For demo purposes - would be removed in production
                if (_isVerifying)
                  Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: TextButton(
                      onPressed: _manualVerifyPayment,
                      child: Text(
                        '(Debug: Simulate successful payment)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}