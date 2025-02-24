import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser(); // Fetch user details when screen initializes
  }

  void _getUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Signed in as: ${_user!.displayName ?? "No Name"}'),
                  SizedBox(height: 10),
                  MaterialButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      setState(() {
                        _user = null; // Ensure UI updates after sign-out
                      });
                    },
                    color: Colors.blueAccent,
                    child: Text("Sign Out", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
