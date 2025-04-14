import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/theme_provider.dart';

class UserSurveyManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if survey should be shown based on app open count
  static Future<bool> shouldShowSurvey() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        print("No user logged in, skipping survey check");
        return false;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userEmail).get();

      if (!userDoc.exists) {
        print("User document doesn't exist, skipping survey check");
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get current app open count from the document
      int appOpenCount = userData['appOpenCount'] ?? 0;
      print("Current app open count: $appOpenCount");

      // Get list of answered surveys
      List<dynamic> answeredSurveys = userData['answeredSurveys'] ?? [];
      print("Answered surveys count: ${answeredSurveys.length}");

      // Get last answered question index
      int lastAnsweredQuestionIndex = userData['lastAnsweredQuestionIndex'] ?? -1;
      print("Last answered question index: $lastAnsweredQuestionIndex");

      // Get last survey app open count
      int lastSurveyAppOpenCount = userData['lastSurveyAppOpenCount'] ?? 0;
      print("Last survey app open count: $lastSurveyAppOpenCount");

      // Get all survey questions
      List<Map<String, dynamic>> allQuestions = await getAllSurveyQuestions();

      // If we have answered all questions, don't show any more surveys
      if (lastAnsweredQuestionIndex >= allQuestions.length - 1) {
        print("All questions have been answered, no more surveys to show");
        return false;
      }

      // Calculate how many app opens since last survey
      int appOpensSinceLastSurvey = appOpenCount - lastSurveyAppOpenCount;
      print("App opens since last survey: $appOpensSinceLastSurvey");

      // If this is the first question (no questions answered yet)
      if (answeredSurveys.isEmpty) {
        // Show first survey after 5 app opens
        bool shouldShow = appOpenCount >= 5;
        print("First survey should show: $shouldShow (need 5 app opens, have $appOpenCount)");
        return shouldShow;
      } else {
        // For subsequent questions, check if it's been 5 more app opens since last survey
        bool shouldShow = appOpensSinceLastSurvey >= 5;
        print("Next survey should show: $shouldShow (need 5 more app opens since last survey, have $appOpensSinceLastSurvey)");
        return shouldShow;
      }
    } catch (e) {
      print("Error checking if survey should be shown: $e");
      return false;
    }
  }

  // Get next survey question to show
  static Future<Map<String, dynamic>?> getNextSurveyQuestion() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        return null;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userEmail).get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get last answered question index
      int lastAnsweredQuestionIndex = userData['lastAnsweredQuestionIndex'] ?? -1;
      print("Last answered question index when getting next question: $lastAnsweredQuestionIndex");

      // Get all survey questions
      List<Map<String, dynamic>> surveyQuestions = await getAllSurveyQuestions();

      // Get next question index
      int nextQuestionIndex = lastAnsweredQuestionIndex + 1;
      print("Next question index: $nextQuestionIndex");

      // If we have a question to show at this index
      if (nextQuestionIndex < surveyQuestions.length) {
        print("Returning question at index $nextQuestionIndex: ${surveyQuestions[nextQuestionIndex]['question']}");
        return surveyQuestions[nextQuestionIndex];
      }

      // If all questions have been answered, return null
      print("No more questions available");
      return null;
    } catch (e) {
      print("Error getting next survey question: $e");
      return null;
    }
  }

  // Get all survey questions
  // Update the getAllSurveyQuestions method in your UserSurveyManager class

  static Future<List<Map<String, dynamic>>> getAllSurveyQuestions() async {
    // Return your new list of questions
    return [
      {
        'id': 'usage_type',
        'question': 'Are you using Vaky for personal use or business?',
        'options': ['Personal', 'Business'],
        'type': 'radio',
        'emoji': '🧠'
      },
      {
        'id': 'template_interest',
        'question': 'What kind of templates are you most interested in creating?',
        'options': ['Wishes', 'Promotions', 'Event invites', 'Quote posts', 'Other'],
        'type': 'radio',
        'emoji': '🧠'
      },
      {
        'id': 'business_name',
        'question': 'What is your business or brand name?',
        'type': 'text',
        'emoji': '🧠'
      },
      {
        'id': 'religion',
        'question': 'Which religion you belong to?',
        'options': ['Hinduism', 'Sikhism', 'Christianity', 'Buddhism', 'Islam', 'Jainism','Parsi'],
        'type': 'radio',
        'emoji': '😊'
      },
      {
        'id': 'content_type',
        'question': 'Which type of content do you share most often?',
        'options': ['Wishes', 'Festival greetings', 'Motivational quotes', 'Product promos'],
        'type': 'radio',
        'emoji': '🧠'
      },
      {
        'id': 'profession',
        'question': 'What do you do professionally?',
        'options': ['Freelancer', 'Influencer', 'Event Organizer', 'Small Business Owner', 'Other'],
        'type': 'radio',
        'emoji': '🧠'
      },
      {
        'id': 'industry',
        'question': 'What industry are you in?',
        'options': ['Fashion', 'Food', 'Tech', 'Education', 'Beauty', 'Fitness', 'Other'],
        'type': 'radio',
        'emoji': '🧠'
      },

      {
        'id': 'share_platform',
        'question': 'Where do you mostly share your posts?',
        'options': ['Instagram', 'WhatsApp', 'Facebook', 'LinkedIn', 'All of them'],
        'type': 'radio',
        'emoji': '🧠'
      },
      {
        'id': 'own_photos',
        'question': 'Would you like to use your own photos in templates?',
        'options': ['YES', 'NO'],
        'type': 'radio',
        'emoji': '😊'
      },

    ];
  }

  // Save survey response to Firestore with explicit return value checking
  // Replace the saveSurveyResponse method in your UserSurveyManager class with this fixed version

  static Future<bool> saveSurveyResponse(String questionId, dynamic response) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        print("No user logged in, can't save survey response");
        return false;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");

      // Get the current user document
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userEmail).get();

      if (!userDoc.exists) {
        print("User document doesn't exist, can't save survey response");
        return false;
      }

      // Get the current data
      final userData = userDoc.data() as Map<String, dynamic>;

      // Get app open count
      int appOpenCount = userData['appOpenCount'] ?? 0;
      print("Current app open count when saving response: $appOpenCount");

      // Get existing answered surveys
      List<dynamic> answeredSurveys = userData['answeredSurveys'] ?? [];

      // Get last answered question index, default to -1 if not set
      int lastAnsweredQuestionIndex = userData['lastAnsweredQuestionIndex'] ?? -1;
      print("Current lastAnsweredQuestionIndex: $lastAnsweredQuestionIndex");

      // Create new survey response - use current timestamp instead of serverTimestamp()
      // This avoids the error with serverTimestamp in arrays
      Map<String, dynamic> newResponse = {
        'id': questionId,
        'response': response,
        'timestamp': Timestamp.now()  // Use client-side timestamp instead of serverTimestamp
      };

      // Add to answered surveys
      answeredSurveys.add(newResponse);
      print("Adding response for question: $questionId with value: $response");

      // Update last answered question index
      lastAnsweredQuestionIndex += 1;
      print("New lastAnsweredQuestionIndex: $lastAnsweredQuestionIndex");

      // Update user document with a complete write to ensure all fields are set
      final updateData = {
        'answeredSurveys': answeredSurveys,
        'lastAnsweredQuestionIndex': lastAnsweredQuestionIndex,
        'lastSurveyAppOpenCount': appOpenCount,
        'lastSurveyShown': FieldValue.serverTimestamp() // This is fine here as it's not in an array
      };

      print("Updating document with modified timestamp approach");

      // Perform the update and await the result
      await _firestore.collection('users').doc(userEmail).update(updateData);

      print("Survey response saved successfully");

      // Verify the update was successful
      DocumentSnapshot updatedDoc = await _firestore.collection('users').doc(userEmail).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      int updatedIndex = updatedData['lastAnsweredQuestionIndex'] ?? -1;

      print("Verified lastAnsweredQuestionIndex after update: $updatedIndex");

      if (updatedIndex != lastAnsweredQuestionIndex) {
        print("Warning: Updated index doesn't match expected value!");
      }

      return true;
    } catch (e) {
      print("Error saving survey response: $e");
      return false;
    }
  }

  // Show survey dialog with improved checking
  // Fix for the duplicate dialog issue in your UserSurveyManager class

// Add this static variable at the top of your UserSurveyManager class
  static bool _isShowingSurvey = false;

// Then replace the showSurveyDialog method with this version:
  static Future<void> showSurveyDialog(BuildContext context) async {
    try {
      // Check if a survey is already being shown to prevent duplicates
      if (_isShowingSurvey) {
        print("Survey dialog is already being shown, ignoring duplicate request");
        return;
      }

      // Set flag to indicate we're showing a survey
      _isShowingSurvey = true;

      // Check if we should show survey
      print("Checking if survey should be shown...");
      bool shouldShow = await shouldShowSurvey();
      print("Survey should show: $shouldShow");

      if (!shouldShow) {
        print("No survey to show at this time");
        _isShowingSurvey = false; // Reset flag
        return;
      }

      // Get next question
      Map<String, dynamic>? question = await getNextSurveyQuestion();
      if (question == null) {
        print("No question available to show");
        _isShowingSurvey = false; // Reset flag
        return;
      }

      print("Showing question: ${question['id']} - ${question['question']}");

      // Show the dialog
      await showDialog(
        context: context,
        barrierDismissible: false, // User must respond to the survey
        builder: (BuildContext context) {
          return SurveyDialog(
            question: question,
            onSubmit: (response) async {
              // First dismiss the dialog
              Navigator.of(context).pop();

              // Then save the response
              print("Saving response: $response for question ${question['id']}");
              bool success = await saveSurveyResponse(question['id'], response);

              if (success) {
                print("Response saved successfully");
              } else {
                print("Failed to save response");
              }

              // Reset the flag after the dialog is closed and response is handled
              _isShowingSurvey = false;
            },
            onSkip: () {
              print("User skipped the question");
              Navigator.of(context).pop();

              // Reset the flag after the dialog is closed
              _isShowingSurvey = false;
            },
          );
        },
      ).then((_) {
        // In case the dialog is dismissed in an unexpected way, reset the flag
        _isShowingSurvey = false;
      });
    } catch (e) {
      print("Error showing survey dialog: $e");
      // Make sure to reset the flag in case of errors
      _isShowingSurvey = false;
    }
  }

  // Increment app open count (call this when home button is clicked)
  static Future<void> incrementAppOpenCount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        print("No user logged in, can't increment app open count");
        return;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");

      // Check if the field exists first
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userEmail).get();
      if (!userDoc.exists) {
        print("User document doesn't exist, can't increment app open count");
        return;
      }

      // Get current count
      final userData = userDoc.data() as Map<String, dynamic>;
      int currentCount = userData['appOpenCount'] ?? 0;

      // Increment and update
      int newCount = currentCount + 1;
      await _firestore.collection('users').doc(userEmail).update({
        'appOpenCount': newCount
      });

      print("App open count incremented from $currentCount to $newCount");

      // Verify the update
      DocumentSnapshot updatedDoc = await _firestore.collection('users').doc(userEmail).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      int updatedCount = updatedData['appOpenCount'] ?? 0;

      print("Verified appOpenCount after update: $updatedCount");
    } catch (e) {
      print("Error incrementing app open count: $e");
    }
  }

  // Reset survey data for testing
  static Future<void> resetSurveyData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        print("No user logged in, can't reset survey data");
        return;
      }

      String userEmail = currentUser.email!.replaceAll(".", "_");

      // Reset all survey fields
      await _firestore.collection('users').doc(userEmail).update({
        'appOpenCount': 0,
        'lastAnsweredQuestionIndex': -1,
        'lastSurveyAppOpenCount': 0,
        'lastSurveyShown': null,
        'answeredSurveys': []
      });

      print("Survey data reset successfully");
    } catch (e) {
      print("Error resetting survey data: $e");
    }
  }
}

// Replace your SurveyDialog class with this updated version


class SurveyDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(dynamic) onSubmit;
  final VoidCallback onSkip;

  const SurveyDialog({
    Key? key,
    required this.question,
    required this.onSubmit,
    required this.onSkip,
  }) : super(key: key);

  @override
  _SurveyDialogState createState() => _SurveyDialogState();
}

class _SurveyDialogState extends State<SurveyDialog> {
  dynamic selectedOption;
  String textResponse = '';
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button as a separate widget above the dialog
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSkip,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : Colors.grey
                        .shade300,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: isDarkMode ? AppColors.darkIcon : Colors.grey
                        .shade700,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 5), // Add some space between the button and dialog
          // Main dialog content
          contentBox(context, isDarkMode),
        ],
      ),
    );
  }

  Widget contentBox(BuildContext context, bool isDarkMode) {
    final dialogBgColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final textColor = isDarkMode ? AppColors.darkText : Colors.black;
    final borderColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade300;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: dialogBgColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SingleChildScrollView(  // Added to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Emoji at the top and question
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.question['emoji'] ?? '😊',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.question['question'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Options based on question type
            if (widget.question['type'] == 'radio')
              ...buildRadioOptions(context, isDarkMode),

            if (widget.question['type'] == 'text')
              buildTextInput(isDarkMode),

            SizedBox(height: 24),

            // Emojis right above the Next button
            Padding(
              padding: EdgeInsets.only(),
              child: Image.asset('assets/emoji.png', height: 30),
            ),

            // Submit button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                minimumSize: Size(120, 50),
              ),
              onPressed: isSubmitting ? null : (isValidResponse() ? submitResponse : null),
              child: isSubmitting
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Here's the complete buildRadioOptions method including SVG for religion icons

  List<Widget> buildRadioOptions(BuildContext context, bool isDarkMode) {
    List<Widget> options = [];
    final textColor = isDarkMode ? AppColors.darkText : Colors.black;
    final borderColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade300;
    final secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : Colors.grey.shade700;

    if (widget.question['id'] == 'religion') {
      // Special grid layout for religion question
      return [
        Column(
          children: [
            buildReligionRow(['Hinduism', 'Sikhism'], isDarkMode),
            SizedBox(height: 10),
            buildReligionRow(['Christianity', 'Buddhism'], isDarkMode),
            SizedBox(height: 10),
            buildReligionRow(['Islam', 'Jainism'], isDarkMode),
            SizedBox(height: 10),
            buildReligionRow(['Parsi'], isDarkMode),
          ],
        )
      ];
    } else if (widget.question['id'] == 'own_photos') {
      // Special layout for yes/no question
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.question['options'].map<Widget>((option) {
            bool isSelected = selectedOption == option;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedOption = option;
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.primaryBlue : borderColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isDarkMode ? AppColors.darkSurface : Colors.white,
                      ),
                      child: Center(
                        child: isSelected
                            ? Icon(Icons.check, color: AppColors.primaryBlue)
                            : null,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      option,
                      style: TextStyle(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ];
    } else {
      // Standard radio options for other questions
      for (String option in widget.question['options']) {
        options.add(
          RadioListTile<String>(
            title: Text(
              option,
              style: TextStyle(color: textColor),
            ),
            value: option,
            groupValue: selectedOption,
            onChanged: (value) {
              setState(() {
                selectedOption = value;
              });
            },
            activeColor: AppColors.primaryBlue,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      }
      return options;
    }
  }

  Widget buildReligionRow(List<String> options, bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.darkText : Colors.black;
    final borderColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade300;
    final secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : Colors.grey.shade700;
    final cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((option) {
        bool isSelected = selectedOption == option;

        // Get SVG path for each religion
        String getSvgPathForReligion(String religion) {
          switch (religion) {
            case 'Hinduism':
              return 'assets/Konark_Sun_Tower.svg';
            case 'Sikhism':
              return 'assets/sikhism.svg';
            case 'Christianity':
              return 'assets/church-bell_9988486.svg';
            case 'Buddhism':
              return 'assets/buddha_4165012 1.svg';
            case 'Islam':
              return 'assets/crescent-moon_3004974.svg';
            case 'Jainism':
              return 'assets/jainism.svg';
            case 'Parsi':
              return 'assets/parsi.svg';
            default:
              return 'assets/icons/default_religion.svg'; // Fallback icon
          }
        }

        // Helper function to handle SVG loading errors
        Widget buildReligionIcon() {
          try {
            return SvgPicture.asset(
              getSvgPathForReligion(option),
              width: 24,
              height: 24,
              // colorFilter: ColorFilter.mode(
              //   secondaryTextColor,
              //   BlendMode.srcIn,
              // ),
            );
          } catch (e) {
            print("Error loading SVG for $option: $e");
            // Fallback to a default icon if SVG fails to load
            return Icon(Icons.image, color: secondaryTextColor, size: 24);
          }
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedOption = option;
            });
          },
          child: Container(
            width: 130, // Fixed width to prevent overflow
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
              color: cardColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use SVG instead of Icon
                buildReligionIcon(),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: secondaryTextColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: AppColors.primaryBlue, size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildTextInput(bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.darkText : Colors.black;
    final borderColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade300;
    final hintColor = isDarkMode ? AppColors.darkSecondaryText : Colors.grey;
    final inputBgColor = isDarkMode ? AppColors.darkSurface : Colors.white;

    return TextField(
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: TextStyle(color: hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        filled: isDarkMode,
        fillColor: isDarkMode ? AppColors.darkSurface : null,
      ),
      maxLines: 2,
      onChanged: (value) {
        setState(() {
          textResponse = value;
        });
      },
    );
  }

  bool isValidResponse() {
    if (widget.question['type'] == 'radio') {
      return selectedOption != null;
    } else if (widget.question['type'] == 'text') {
      return textResponse.trim().isNotEmpty;
    }
    return false;
  }

  void submitResponse() {
    setState(() {
      isSubmitting = true;
    });

    dynamic response = widget.question['type'] == 'radio' ? selectedOption : textResponse;
    widget.onSubmit(response);
  }
}