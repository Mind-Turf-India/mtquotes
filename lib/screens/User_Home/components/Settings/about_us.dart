import 'package:flutter/material.dart';
import 'package:mtquotes/l10n/app_localization.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(context.loc.aboutus),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo or icon
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // App name and headline
            Center(
              child: Text(
                "Vaky",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  "The Ultimate Quote & Status Maker",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // What is Vaky?
            _buildSection(
              context,
              "What is Vaky?",
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  children: [
                    const TextSpan(
                      text: "Vaky is a powerful quote-making app ",
                      
                    ),
                    const TextSpan(text: "designed to help you "),
                    const TextSpan(
                      text:
                          "create, edit, and customize stunning quote images ",
                      
                    ),
                    const TextSpan(text: "for social media. Whether it's "),
                    const TextSpan(
                      text:
                          "motivational quotes, life quotes, inspirational messages, or aesthetic text posts",
                      
                    ),
                    const TextSpan(text: ", Vaky makes it "),
                    const TextSpan(
                      text: "quick, easy, and fun!",
                     
                    ),
                  ],
                ),
              ),
            ),

            // Why Vaky?
            _buildSection(
              context,
              "Why Vaky?",
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  children: [
                    const TextSpan(
                      text: "At ",
                    ),
                    const TextSpan(
                      text: "Vaky",
                      
                    ),
                    const TextSpan(
                        text:
                            ", we believe in the power of words. Our app is built for "),
                    const TextSpan(
                      text: "writers, influencers, and status lovers ",
                      
                    ),
                    const TextSpan(
                        text: "who want to express themselves through "),
                    const TextSpan(
                      text:
                          "beautifully designed WhatsApp status, attitude quotes, and love Shayari",
                     
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),

            // What Can You Do with Vaky?
            _buildSection(
              context,
              "What Can You Do with Vaky?",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    "Create & Edit Quotes",
                    "Design unique WhatsApp status quotes, attitude Shayari (2 lines), and love Shayari in Hindi.",
                  ),
                  _buildFeatureItem(
                    "Stylish Status Maker",
                    "Make eye-catching romantic status, attitude quotes in English, and short poems.",
                  ),
                  _buildFeatureItem(
                    "All-in-One Photo & Text Editor",
                    "Perfect for motivational quotes, WhatsApp status updates, and Shayari lovers.",
                  ),
                  _buildFeatureItem(
                    "Fast & Easy to Use",
                    "Just type, customize, and save your quotes instantly with Vaky!",
                  ),
                ],
              ),
            ),

            // How Vaky Works?
            _buildSection(
              context,
              "How Vaky Works?",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Using Vaky is super simple:",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildNumberedItem(
                
                    "Choose a Background",
                    "Pick from our built-in designs or use your own images.",
                  ),
                  _buildNumberedItem(
                 
                    "Write Your Quote",
                    "Add motivational, romantic, or attitude-based text.",
                  ),
                  _buildNumberedItem(
                    
                    "Customize & Save",
                    "Change font styles, colors, and alignment to match your vibe.",
                  ),
                  _buildNumberedItem(
                    
                    "Share Instantly",
                    "Post your quote on WhatsApp, Instagram, Facebook, and more!",
                  ),
                ],
              ),
            ),

            // Why Choose Vaky?
            _buildSection(
              context,
              "Why Choose Vaky?",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCheckItem(
                    "Lightweight & Fast",
                    "Works smoothly on all devices.",
                  ),
                  _buildCheckItem(
                    "Free to Download",
                    "Available on Google Play Store.",
                  ),
                  _buildCheckItem(
                    "Best Quote Maker App",
                    "Perfect for quotes, WhatsApp status, and aesthetic posts.",
                  ),
                  _buildCheckItem(
                    "Express Yourself Creatively",
                    "A powerful yet simple app for content lovers.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Call to action
            

            const SizedBox(height: 32),

            // Version and copyright
            Center(
              child: Text(
                "Version 1.0.0",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "© 2025 Vaky. All rights reserved.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$title ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "– $description"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem( String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$title ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "– $description"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$title ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "– $description"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
