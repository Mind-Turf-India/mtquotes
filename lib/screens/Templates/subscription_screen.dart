import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'components/template/template_service.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TemplateService _templateService = TemplateService();
  bool _isLoading = false;
  String _selectedPlan = 'monthly';

  @override
  Widget build(BuildContext context) {
    double fontSize = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Subscription'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Upgrade to Pro',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Get unlimited access to all premium templates',
              style: GoogleFonts.poppins(fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            // Features
            _buildFeatureItem(
              icon: Icons.check_circle,
              text: 'Access all premium templates',
              fontSize: fontSize,
            ),
            _buildFeatureItem(
              icon: Icons.check_circle,
              text: 'No watermarks on exported quotes',
              fontSize: fontSize,
            ),
            _buildFeatureItem(
              icon: Icons.check_circle,
              text: 'Priority access to new designs',
              fontSize: fontSize,
            ),
            _buildFeatureItem(
              icon: Icons.check_circle,
              text: 'Premium customer support',
              fontSize: fontSize,
            ),
            SizedBox(height: 30),

            // Plan selection
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPlanOption(
                    title: 'Monthly Plan',
                    price: '\$4.99',
                    period: 'per month',
                    value: 'monthly',
                    fontSize: fontSize,
                  ),
                  Divider(height: 1),
                  _buildPlanOption(
                    title: 'Annual Plan',
                    price: '\$39.99',
                    period: 'per year',
                    value: 'annual',
                    fontSize: fontSize,
                    badge: 'Save 33%',
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Subscribe button
            ElevatedButton(
              onPressed: () => _handleSubscription(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Subscribe Now',
                style: TextStyle(fontSize: fontSize),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'You can cancel your subscription anytime from your account settings',
              style: TextStyle(
                fontSize: fontSize - 4,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required double fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: fontSize + 4,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String period,
    required String value,
    required double fontSize,
    String? badge,
  }) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: fontSize - 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      value: value,
      groupValue: _selectedPlan,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedPlan = newValue;
          });
        }
      },
    );
  }

  Future<void> _handleSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Here you would implement your payment processing logic
      // For this example, we'll just simulate a successful subscription
      await Future.delayed(Duration(seconds: 2));

      // Update user subscription status
      await _templateService.updateSubscriptionStatus(true);

      // Show success message and return to previous screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}