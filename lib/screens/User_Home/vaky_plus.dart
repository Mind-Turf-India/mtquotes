import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_screen.dart';
import '../../utils/app_colors.dart';
import 'components/Doc Scanner/doc_scanner.dart';
import 'components/Invoice/invoice_welcome.dart';
import 'components/Resume/resume_dashboard.dart';

class VakyPlus extends StatelessWidget {
  const VakyPlus({Key? key}) : super(key: key);

  void navigateTo(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            SvgPicture.asset('assets/icons/vaky_plus_wobg.svg', height: 90),
            const SizedBox(height: 30),
            featureCard(
              context,
              title: "Document Scanner",
              description: "Scan, Save, and Share Documents in Seconds.",
              buttonText: "Scan Now",
              imagePath: "assets/icons/doc scanner light.svg",
              destination: const DocScanner(),
              backgroundColor: const Color(0x802897FF),
              imageHeight: 130,
              imageWidth: 130,
            ),
            featureCard(
              context,
              title: "Resume",
              description: "Create a professional resume in minutes.",
              buttonText: "Create Resume",
              imagePath: "assets/icons/resume.svg",
              destination: const PersonalDetailsScreen(),
              backgroundColor: const Color(0xB32897FF),
              imageHeight: 130,
              imageWidth: 130,
            ),
            featureCard(
              context,
              title: "Invoice",
              description: "Fast, simple, and professional invoice generation.",
              buttonText: "Create Invoice",
              imagePath: "assets/icons/create_invoice.svg",
              destination: InvoiceHomeScreen(),
              backgroundColor: AppColors.primaryBlue,
              imageHeight: 130,
              imageWidth: 130,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text(
                "Upgrade",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget featureCard(
      BuildContext context, {
        required String title,
        required String description,
        required String buttonText,
        required String imagePath,
        required Widget destination,
        required Color backgroundColor,
        required double imageHeight,
        required double imageWidth,
      }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black45 : Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => navigateTo(context, destination),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getSurfaceColor(isDarkMode),
                        foregroundColor: AppColors.getTextColor(isDarkMode),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(buttonText),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  imagePath,
                  height: imageHeight,
                  width: imageWidth,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
