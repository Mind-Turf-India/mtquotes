import 'package:flutter/material.dart';

class SubscriptionPopup {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Upgrade to Access Premium Templates'),
          content: Text('Subscribe to unlock all premium templates and enjoy unlimited access to our entire collection.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to subscription screen
                Navigator.pushNamed(context, '/subscription');
              },
              child: Text('Buy Plan'),
            ),
          ],
        );
      },
    );
  }
}