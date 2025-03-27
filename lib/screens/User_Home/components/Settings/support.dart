import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/l10n/app_localization.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
    // List to track which FAQs are expanded
  List<bool> _isExpanded = List.filled(4, false);

  // FAQ questions and answers
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Is Vaky for Free?',
      'answer': 'Vaky offers both free and paid plans. The free plan includes basic features, while premium features require a subscription.'
    },
    {
      'question': 'How many template can I download?',
      'answer': 'The number of templates you can download depends on your current plan. Free users have limited downloads, while paid users have unlimited access.'
    },
    {
      'question': 'What is sharing limit?',
      'answer': 'Sharing limits vary based on your subscription tier. Check our pricing page for detailed information on sharing capabilities.'
    },
    {
      'question': 'How to use?',
      'answer': 'To use Vaky, first create an account, select a template, customize it to your needs, and then download or share as required.'
    }
  ];

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                 
                  Text(
                    'Support',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      
                    ),
                  ),
                  Spacer(),
                  
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mail Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.mail_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              'Mail',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),

                      // Write a Message
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Write a message',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Message TextField
                      TextField(
                        maxLines: 4,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Max 100 words...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      // Submit Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Text('Submit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // FAQs Title
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'FAQ\'s',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Expandable FAQs
                      ...List.generate(_faqs.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpanded[index] = !_isExpanded[index];
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _faqs[index]['question']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Icon(
                                        _isExpanded[index] 
                                          ? Icons.remove 
                                          : Icons.add,
                                        color: Colors.blue,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              if (_isExpanded[index])
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    _faqs[index]['answer']!,
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Robot Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.support_agent),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

