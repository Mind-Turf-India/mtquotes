//import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mtquotes/screens/Templates/payment_handler.dart';
import 'package:pay/pay.dart';
import 'dart:math';


class PaymentScreen extends StatefulWidget {
  final String planType;
  final String amount;
  final String userName;
  final bool isSubscription;
  final int trialDays;
  final String? recurringType;
  final String? fullAmount;

  const PaymentScreen({
    Key? key,
    required this.planType,
    required this.amount,
    required this.userName,
    this.isSubscription = false,
    this.trialDays = 0,
    this.recurringType,
    this.fullAmount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _error;
  String _transactionId = '';
  UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? _upiApps;

  // Supported payment providers
  final List<PayProvider> _paymentProviders = [
    PayProvider.google_pay,
  ];

  // Payment configurations
  late final Map<PayProvider, List<PaymentItem>> _paymentItems;
  late final Map<PayProvider, PaymentConfiguration> _paymentConfigurations;

  @override
  void initState() {
    super.initState();
    _generateTransactionId();
    _initializePaymentConfigurations();
    _getUpiApps();
  }

  Future<void> _getUpiApps() async {
    try {
      _upiApps = await _upiIndia.getAllUpiApps();
      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Error loading UPI apps: ${e.toString()}';
      });
    }
  }

  void _generateTransactionId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    _transactionId = 'TXN_' +
        List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _initializePaymentConfigurations() {
    // Create payment items
    final paymentItems = [
      PaymentItem(
        amount: widget.amount,
        label: widget.planType,
        status: PaymentItemStatus.final_price,
      )
    ];

    // Set up Google Pay configuration
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
          "merchantName": "Your App Name"
        },
        "transactionInfo": {
          "countryCode": "IN",
          "currencyCode": "INR"
        }
      }
    }
    ''');

    // Initialize payment configurations map
    _paymentConfigurations = {
      PayProvider.google_pay: googlePayConfig,
    };

    // Initialize payment items map
    _paymentItems = {
      PayProvider.google_pay: paymentItems,
    };
  }

  Future<void> _processPayment(Map<String, dynamic> paymentResult) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;
      final uid = user?.uid ?? 'unknown';

      // Extract payment details
      final String paymentStatus = paymentResult['status'] ?? '';
      final String paymentId = paymentResult['id'] ?? _transactionId;

      if (paymentStatus.toLowerCase() == 'success') {
        await _updateUserSubscription(uid, paymentResult);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment successful!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after a short delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Transaction failed or canceled"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error processing payment: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserSubscription(String uid, Map<String, dynamic> paymentResult) async {
    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(uid);

      // Create transaction record
      await db.collection('transactions').add({
        'userId': uid,
        'planType': widget.planType,
        'amount': double.parse(widget.amount),
        'transactionId': _transactionId,
        'paymentId': paymentResult['id'] ?? '',
        'paymentMethod': paymentResult['paymentMethodType'] ?? 'unknown',
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
        'isSubscription': widget.isSubscription,
        'trialDays': widget.trialDays,
        'recurringType': widget.recurringType,
      });

      // Update user subscription status
      Map<String, dynamic> subscriptionData = {
        'lastPayment': FieldValue.serverTimestamp(),
        'activePlan': widget.planType,
      };

      // Handle different subscription types
      if (widget.isSubscription) {
        DateTime now = DateTime.now();
        DateTime endDate;

        if (widget.recurringType == 'monthly') {
          endDate = DateTime(now.year, now.month + 1, now.day);
        } else if (widget.recurringType == 'quarterly') {
          if (widget.trialDays > 0) {
            // First set trial end date
            DateTime trialEndDate = now.add(Duration(days: widget.trialDays));
            subscriptionData['trialEndDate'] = trialEndDate;
            endDate = DateTime(trialEndDate.year, trialEndDate.month + 3, trialEndDate.day);
          } else {
            endDate = DateTime(now.year, now.month + 3, now.day);
          }
        } else if (widget.recurringType == 'annual') {
          endDate = DateTime(now.year + 1, now.month, now.day);
        } else {
          // Default fallback
          endDate = DateTime(now.year, now.month + 1, now.day);
        }

        subscriptionData['subscriptionEndDate'] = endDate;
        subscriptionData['isActive'] = true;
        subscriptionData['autoRenew'] = true;
        subscriptionData['subscriptionType'] = widget.recurringType;

        if (widget.trialDays > 0) {
          subscriptionData['inTrial'] = true;
          subscriptionData['nextBillingAmount'] = widget.fullAmount;
          subscriptionData['nextBillingDate'] = DateTime.now().add(Duration(days: widget.trialDays));
        } else {
          subscriptionData['inTrial'] = false;
        }
      } else {
        // For per-template purchases, add points
        await userRef.update({
          'points': FieldValue.increment(20), // Add 20 points as per your pricing model
        });
      }

      await userRef.update(subscriptionData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating subscription: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUpiPayment(UpiApp app) async {
    final UpiTransactionResponse response = await _upiIndia.startTransaction(
      app: app,
      receiverUpiId: "your-merchant-upi-id@upi", // Replace with your UPI ID
      receiverName: "Your App Name",
      transactionRefId: _transactionId,
      transactionNote: "Payment for ${widget.planType}",
      amount: double.parse(widget.amount),
    );

    Map<String, dynamic> paymentResult = {
      'status': response.status == UpiPaymentStatus.SUCCESS ? 'success' : 'failed',
      'id': response.transactionId ?? _transactionId,
      'paymentMethodType': 'upi',
      'approvalRefNo': response.approvalRefNo,
    };

    _processPayment(paymentResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text("Error: $_error"))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment details card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Details",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildPaymentDetailRow("Plan", widget.planType),
                    _buildPaymentDetailRow("Amount", "₹${widget.amount}"),
                    if (widget.isSubscription)
                      _buildPaymentDetailRow("Type", "Subscription"),
                    if (widget.trialDays > 0) ...[
                      _buildPaymentDetailRow("Trial Period", "${widget.trialDays} days"),
                      _buildPaymentDetailRow("After Trial", "₹${widget.fullAmount}"),
                    ],
                    _buildPaymentDetailRow("Name", widget.userName),
                    _buildPaymentDetailRow("Transaction ID", _transactionId),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Select Payment Method",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            // Payment buttons
            Column(
              children: [
                // Google Pay button
                GooglePayButton(
                  paymentConfiguration: _paymentConfigurations[PayProvider.google_pay]!,
                  paymentItems: _paymentItems[PayProvider.google_pay]!,
                  type: GooglePayButtonType.pay,
                  margin: const EdgeInsets.only(top: 10.0),
                  onPaymentResult: _processPayment,
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                SizedBox(height: 16),
                // UPI Pay button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      builder: (context) => UpiPaymentSheet(
                        upiApps: _upiApps ?? [],
                        onAppSelected: _handleUpiPayment,
                      ),
                    );
                  },
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text("Pay with UPI"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Terms and conditions
            if (widget.isSubscription)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Subscription Terms:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (widget.trialDays > 0)
                      Text(
                        "• You will be charged ₹${widget.amount} for the first ${widget.trialDays} days. After the trial period, you will be automatically charged ₹${widget.fullAmount}.",
                        style: TextStyle(fontSize: 12),
                      ),
                    Text(
                      "• This is a recurring payment that will continue until cancelled.",
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      "• You can cancel your subscription at any time from your profile.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom UPI Payment Sheet
class UpiPaymentSheet extends StatelessWidget {
  final List<UpiApp> upiApps;
  final Function(UpiApp) onAppSelected;

  const UpiPaymentSheet({
    Key? key,
    required this.upiApps,
    required this.onAppSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select UPI App",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          upiApps.isEmpty
              ? Center(
            child: Text(
              "No UPI apps found on your device",
              style: TextStyle(fontSize: 16),
            ),
          )
              : SizedBox(
            height: 120,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: upiApps.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final app = upiApps[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onAppSelected(app);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image.memory(
                      //   app.icon!,
                      //   height: 40,
                      //   width: 40,
                      // ),
                      SizedBox(height: 4),
                      Text(
                        app.name!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// UPI Payment Status enum
enum UpiPaymentStatus {
  SUCCESS,
  SUBMITTED,
  FAILURE,
  OTHER
}

// UPI App model
class UpiApp {
  final String? name;
  final String? packageName;
  //final Uint8List? icon;

  UpiApp({this.name, this.packageName});
}

// Mock UPI India class for implementation
class UpiIndia {
  Future<List<UpiApp>> getAllUpiApps() async {
    // This would normally come from a UPI package
    // This is a mock implementation
    return [];
  }

  Future<UpiTransactionResponse> startTransaction({
    required UpiApp app,
    required String receiverUpiId,
    required String receiverName,
    required String transactionRefId,
    required String transactionNote,
    required double amount,
  }) async {
    // This would normally make a real UPI payment
    // This is a mock implementation
    return UpiTransactionResponse(
      status: UpiPaymentStatus.SUCCESS,
      transactionId: "mock_txn_${DateTime.now().millisecondsSinceEpoch}",
      approvalRefNo: "mock_ref_${DateTime.now().millisecondsSinceEpoch}",
    );
  }
}

// UPI Transaction Response
class UpiTransactionResponse {
  final UpiPaymentStatus status;
  final String? transactionId;
  final String? approvalRefNo;

  UpiTransactionResponse({
    required this.status,
    this.transactionId,
    this.approvalRefNo,
  });
}