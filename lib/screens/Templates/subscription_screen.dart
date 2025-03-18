import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_screen.dart';
import 'components/template/template_service.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TemplateService _templateService = TemplateService();
  bool _isLoading = false;
  String _selectedPlan = 'free'; // Default to free plan
  final String _userName = "John Doe"; // This would come from your user profile

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Free Plan
            _buildPlanCard(
              planTitle: 'FREE',
              planColor: Colors.blue.shade100,
              features: [
                'Free 200 points',
                'First 10 free shares / downloads',
              ],
              price: null,
              currency: null,
              buttonTitle: 'Existing Plan',
              isPro: false,
              isCurrentPlan: _selectedPlan == 'free',
              onPressed: () {
                setState(() {
                  _selectedPlan = 'free';
                });
              },
              buttonAction: null,
              amount: '0',
              trialDays: 0,
            ),
            SizedBox(height: 16),

            // Per Template Plan
            _buildPlanCard(
              planTitle: 'Per Template',
              planColor: Color(0xFFFFF3E0), // Light peach color
              features: [
                '20 points credited',
                'Single template share',
                'No editing allowed',
              ],
              price: '19',
              currency: '₹',
              buttonTitle: 'Buy Now',
              isPro: false,
              isCurrentPlan: _selectedPlan == 'perTemplate',
              onPressed: () {
                setState(() {
                  _selectedPlan = 'perTemplate';
                });
              },
              buttonAction: () => _navigateToPayment(
                'Per Template',
                '19',
                false,
                0,
                null,
              ),
              amount: '19',
              trialDays: 0,
            ),
            SizedBox(height: 16),

            // Monthly Plan
            _buildPlanCard(
              planTitle: 'Monthly Plan',
              planColor: Colors.green.shade50,
              features: [
                'No points required',
                '10 templates per day to share/download',
                'Editing allowed',
                'Limited features',
                'Auto-pay monthly',
              ],
              price: '99',
              currency: '₹',
              buttonTitle: 'Buy Now',
              isPro: true,
              isCurrentPlan: _selectedPlan == 'monthly',
              onPressed: () {
                setState(() {
                  _selectedPlan = 'monthly';
                });
              },
              buttonAction: () => _navigateToPayment(
                'Monthly Plan',
                '99',
                true,
                0,
                'monthly',
              ),
              amount: '99',
              trialDays: 0,
            ),
            SizedBox(height: 16),

            // Quarterly Plan with Trial
            _buildPlanCard(
              planTitle: 'Quarterly Plan',
              planColor: Colors.purple.shade50,
              features: [
                'No points required',
                '3-day trial for ₹9 only',
                'Unlimited templates',
                'Full editing capabilities',
                'Premium features',
                'Auto-pay quarterly (₹290 after trial)',
                'Cancel anytime',
              ],
              price: '299',
              currency: '₹',
              buttonTitle: 'Start Trial',
              isPro: true,
              isCurrentPlan: _selectedPlan == 'quarterly',
              onPressed: () {
                setState(() {
                  _selectedPlan = 'quarterly';
                });
              },
              buttonAction: () => _navigateToPayment(
                'Quarterly Plan',
                '9',
                true,
                3,
                'quarterly',
              ),
              amount: '299',
              trialDays: 3,
              trialAmount: '9',
            ),
            SizedBox(height: 16),

            // Annual Plan
            _buildPlanCard(
              planTitle: 'Annual Plan',
              planColor: Colors.amber.shade50,
              features: [
                'Best value',
                'No points required',
                'Unlimited templates',
                'Full editing capabilities',
                'Premium features',
                'Auto-pay annually',
              ],
              price: '499',
              currency: '₹',
              buttonTitle: 'Buy Now',
              isPro: true,
              isCurrentPlan: _selectedPlan == 'annual',
              onPressed: () {
                setState(() {
                  _selectedPlan = 'annual';
                });
              },
              buttonAction: () => _navigateToPayment(
                'Annual Plan',
                '499',
                true,
                0,
                'annual',
              ),
              amount: '499',
              trialDays: 0,
              bestValue: true,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPayment(
      String planType,
      String amount,
      bool isSubscription,
      int trialDays,
      String? recurringType,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          planType: planType,
          amount: amount,
          userName: _userName,
          isSubscription: isSubscription,
          trialDays: trialDays,
          recurringType: recurringType,
          fullAmount: trialDays > 0 ? '290' : amount,
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planTitle,
    required Color planColor,
    required List<String> features,
    required String? price,
    required String? currency,
    required String buttonTitle,
    required bool isPro,
    required bool isCurrentPlan,
    required VoidCallback onPressed,
    required VoidCallback? buttonAction,
    required String amount,
    required int trialDays,
    String? trialAmount,
    bool bestValue = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: planColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentPlan ? Colors.blue : Colors.transparent,
            width: isCurrentPlan ? 2 : 0,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Plan details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (price != null && currency != null) ...[
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2),
                            Text(
                              price,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (trialDays > 0) ...[
                        SizedBox(height: 4),
                        Text(
                          '₹$trialAmount for first $trialDays days',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Right side - PRO badge if applicable
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isPro)
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (bestValue) ...[
                      SizedBox(height: 4),
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BEST VALUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // Features list
            ...features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: 16),
            // Action button
            if (buttonAction != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: buttonAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    buttonTitle,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(buttonTitle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}