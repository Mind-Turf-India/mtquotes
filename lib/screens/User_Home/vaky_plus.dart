import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_screen.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            SvgPicture.asset('assets/icons/Vaky plus.svg', height: 60),
            // const SizedBox(height: 10),
            // const Text(
            //   '"vaky"',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            const SizedBox(height: 30),
            featureCard(
              context,
              title: "Document Scanner",
              description: "Scan, Save, and Share Documents in Seconds.",
              buttonText: "Scan Now",
              imagePath: "assets/icons/document_scanner.svg",
              destination: const DocScanner(),
            ),
            featureCard(
              context,
              title: "Resume",
              description: "Create a professional resume in minutes.",
              buttonText: "Create Resume",
              imagePath: "assets/icons/resume.svg",
              destination: const PersonalDetailsScreen(),
            ),
            featureCard(
              context,
              title: "Invoice",
              description: "Fast, simple, and professional invoice generation.",
              buttonText: "Create Invoice",
              imagePath: "assets/icons/create_invoice.svg",
              destination: InvoiceHomeScreen(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text(
                "Upgrade",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => navigateTo(context, destination),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(buttonText),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(imagePath, height: 90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
