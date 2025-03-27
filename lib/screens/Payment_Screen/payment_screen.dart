import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'success_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class PaymentScreen extends StatefulWidget {
  final String planType;
  final String amount;
  final String userName;
  final bool isSubscription;
  final int trialDays;
  final String? recurringType;
  final String fullAmount;

  const PaymentScreen({
    Key? key,
    required this.planType,
    required this.amount,
    required this.userName,
    required this.isSubscription,
    required this.trialDays,
    this.recurringType,
    required this.fullAmount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late String _transactionId;
  late String _paymentNote;
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  String? _selectedUpiApp;
  final platform = const MethodChannel('com.example.mtquotes/upi_intent');

  // List of UPI apps with their icons and package names
  final List<Map<String, String>> _upiApps = [
    {
      'name': 'Google Pay',
      'icon': 'assets/icons/gpay.png',
      'package': 'com.google.android.apps.nbu.paisa.user'
    },
    {
      'name': 'PhonePe',
      'icon': 'assets/icons/phonepe.png',
      'package': 'com.phonepe.app'
    },
    {
      'name': 'Paytm',
      'icon': 'assets/icons/paytm.png',
      'package': 'net.one97.paytm'
    },
    {
      'name': 'BHIM UPI',
      'icon': 'assets/icons/bhim.png',
      'package': 'in.org.npci.upiapp'
    },
  ];

  @override
  void initState() {
    super.initState();
    _transactionId = Uuid().v4(); // Generate a unique transaction ID
    _paymentNote = 'Payment for ${widget.planType}';
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }


  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the user
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final String docId = user.email!.replaceAll('.', '_');

      // Create payment record
      await _createPaymentRecord(docId);
      print("Payment created in firestore");

      // Create UPI URL
      final String upiUrl = _createUpiUrl(docId);
      print("Deeplink: $upiUrl");

      // Launch the URL without specifying a package, which will
      // make Android show the app chooser with all compatible apps
      final Uri uri = Uri.parse(upiUrl);

      if (await canLaunchUrl(uri)) {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          _navigateToSuccessScreen();
        } else {
          throw 'Failed to launch UPI apps';
        }
      } else {
        throw 'No UPI apps available on this device';
      }
    } catch (e) {
      print("Payment error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPaymentRecord(String userId) async {
    // Get the current timestamp
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    // Calculate subscription end date if applicable
    DateTime? endDate;
    if (widget.isSubscription) {
      if (widget.recurringType == 'monthly') {
        endDate = DateTime(now.year, now.month + 1, now.day);
      } else if (widget.recurringType == 'quarterly') {
        endDate = DateTime(now.year, now.month + 3, now.day);
      } else if (widget.recurringType == 'annual') {
        endDate = DateTime(now.year + 1, now.month, now.day);
      }

      // Adjust for trial period
      if (widget.trialDays > 0) {
        endDate = now.add(Duration(days: widget.trialDays));
      }
    }

    // Create payment document
    await _firestore.collection('payments').doc(_transactionId).set({
      'userId': userId,
      'userName': widget.userName,
      'planType': widget.planType,
      'amount': widget.amount,
      'fullAmount': widget.fullAmount,
      'transactionId': _transactionId,
      'paymentNote': _paymentNote,
      'timestamp': timestamp,
      'status': 'pending',
      'paymentMethod': 'upi',
      'upiApp': _selectedUpiApp,
      'isSubscription': widget.isSubscription,
      'trialDays': widget.trialDays,
      'recurringType': widget.recurringType,
      'startDate': timestamp,
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'isTrial': widget.trialDays > 0,
    });

    // Update user's subscription status
    await _firestore.collection('users').doc(userId).update({
      'currentPlan': widget.planType,
      'subscriptionStatus': 'pending',
      'subscriptionStartDate': timestamp,
      'subscriptionEndDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'transactionId': _transactionId,
      'isTrial': widget.trialDays > 0,
    });
  }

  String _createUpiUrl(String userId) {
    // Your merchant UPI ID - replace with your actual UPI ID
    const String merchantUpiId = '9911002977@okbizaxis';

    // Create UPI URL with all necessary parameters
    final String upiUrl = 'upi://pay?pa=$merchantUpiId'
        '&pn=Vaky'
        '&tr=$_transactionId'
        '&am=${widget.amount}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent(_paymentNote)}'
        // '&mc=your-merchant-code' // Optional: Your merchant category code
        '&refUrl=${Uri.encodeComponent('https://yourapp.com')}';

    return upiUrl;
  }

  void _navigateToSuccessScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessScreen(
          transactionId: _transactionId,
          planType: widget.planType,
          amount: widget.amount,
          isSubscription: widget.isSubscription,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment summary card
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
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildSummaryRow('Plan', widget.planType),
                      _buildSummaryRow('User', widget.userName),
                      _buildSummaryRow('Amount', '₹${widget.amount}'),
                      if (widget.trialDays > 0)
                        _buildSummaryRow(
                          'Trial',
                          '${widget.trialDays} days (₹${widget.fullAmount} after trial)',
                        ),
                      if (widget.isSubscription && widget.recurringType != null)
                        _buildSummaryRow(
                          'Billing Cycle',
                          widget.recurringType!.substring(0, 1).toUpperCase() +
                              widget.recurringType!.substring(1),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // UPI App Selection
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // UPI app grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _upiApps.length,
                itemBuilder: (context, index) {
                  final app = _upiApps[index];
                  final bool isSelected = _selectedUpiApp == app['package'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedUpiApp = app['package'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            app['icon']!,
                            height: 40,
                            width: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            app['name']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 32),

              // Pay Now button
              ElevatedButton(
                onPressed: _initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Pay ₹${widget.amount} Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Terms and conditions text
              Text(
                widget.isSubscription
                    ? 'By proceeding, you agree to the terms of subscription and authorize recurring payments as per the selected plan.'
                    : 'By proceeding, you agree to the terms of payment.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}