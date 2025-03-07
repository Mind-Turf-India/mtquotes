import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/quote_template.dart';
import 'package:mtquotes/screens/Templates/subscription_popup.dart';
import 'package:mtquotes/screens/Templates/template_section.dart';
import 'package:mtquotes/screens/Templates/template_service.dart';
import 'package:mtquotes/screens/User_Home/components/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  String greetings = "";
  String? qotdImageUrl;
  final TemplateService _templateService = TemplateService();

  @override
  void initState() {
    super.initState();
    _fetchUserDisplayName();
    _fetchQOTDImage();
     _checkUserProfile();
  }

void _checkUserProfile() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!userDoc.exists || userDoc['name'] == null || userDoc['bio'] == null) {
    Future.delayed(Duration.zero, () => _showUserProfileDialog());
  }
}

void _showUserProfileDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing without completing
    builder: (context) {
      TextEditingController nameController = TextEditingController();
      TextEditingController bioController = TextEditingController();
      File? _selectedImage;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Complete Your Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedImage = await _pickImage();
                    if (pickedImage != null) {
                      setState(() {
                        _selectedImage = pickedImage;
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(labelText: "Bio"),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await _updateUserProfile(nameController.text, bioController.text, _selectedImage);
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<File?> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}

Future<void> _updateUserProfile(String name, String bio, File? image) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String? imageUrl;
  if (image != null) {
    imageUrl = await _uploadProfileImage(user.uid, image);
  }

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'name': name,
    'bio': bio,
    'profileImage': imageUrl,
  }, SetOptions(merge: true));

  setState(() {
    userName = name;
  });
}

Future<String?> _uploadProfileImage(String uid, File image) async {
  Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
  UploadTask uploadTask = storageRef.putFile(image);
  TaskSnapshot snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}

  

  void _fetchUserDisplayName() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      setState(() {
        userName = user.displayName!;
      });
    }
  }

  void _handleTemplateSelection(QuoteTemplate template) async {
    bool isSubscribed = await _templateService.isUserSubscribed();

    if (!template.isPaid || isSubscribed) {
      // Navigate to template editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(title: 'image',),
        ),
      );
    } else {
      // Show subscription popup
      SubscriptionPopup.show(context);
    }
  }


  String _getGreeting(BuildContext context) {
    int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return context.loc.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return context.loc.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return context.loc.goodEvening;
    } else {
      return context.loc.goodNight;
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NotificationsSheet(),
    );
  }

  Future<void> _fetchQOTDImage() async {
    String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    print('date fetched');
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('qotd')
          .doc(formattedDate)
          .get();
      print('snapshot taken');
      if (snapshot.exists && snapshot["imageURL"] != null) {
        setState(() {
          qotdImageUrl = snapshot["imageURL"];
        });
        print('image stored');
      }
    } catch (e) {
      print("Error fetching QOTD: $e");
    }
  }

  void shareImage(String? qotdImageUrl) async {
  if (qotdImageUrl != null && qotdImageUrl.isNotEmpty) {
    try {
      final uri = Uri.parse(qotdImageUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/quote_image.jpg';
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        /// ✅ Correct way to share files using `share_plus`
        await Share.shareXFiles([XFile(filePath)], text: "Quote of the Day");
      } else {
        debugPrint("Failed to download image");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  } else {
    await Share.share("Check out this amazing quote!");
  }
}

  @override
  Widget build(BuildContext context) {
    greetings = _getGreeting(context);
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize; // Get font size

    return WillPopScope(
      onWillPop: () async =>
          false, // Prevents navigating back to the login screen
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(LucideIcons.user, color: Colors.black)),
              ),
              SizedBox(width: 20),
              Text(
                "Hi, $userName\n$greetings",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Spacer(),
              GestureDetector(
                onTap: _showNotificationsSheet,
                child: Icon(
                  LucideIcons.bellRing,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Quote of the Day
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent, 
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: qotdImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: qotdImageUrl!,
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[300], // Fallback background
                                alignment: Alignment.center,
                                child: Text(
                                  "No quote available today",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 35,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => shareImage(qotdImageUrl),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share, color: Colors.white),
                            SizedBox(width: 6),
                            Text("Share",
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                Text(context.loc.recents,
                    style: GoogleFonts.poppins(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      quoteCard("Everything requires hard work.", fontSize),
                      quoteCard("Success comes from daily efforts.", fontSize),
                      quoteCard("Believe in yourself.", fontSize),
                      quoteCard("Believe in yourself.", fontSize),
                      quoteCard("Believe in yourself.", fontSize),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(height: 20),

                // Categories
                Text(context.loc.categories,
                    style: GoogleFonts.poppins(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      categoryCard(Icons.lightbulb, context.loc.motivational,
                          Colors.green, fontSize),
                      categoryCard(Icons.favorite, context.loc.love, Colors.red,
                          fontSize),
                      categoryCard(Icons.emoji_emotions, context.loc.funny,
                          Colors.orange, fontSize),
                      categoryCard(Icons.people, context.loc.friendship,
                          Colors.blue, fontSize),
                      categoryCard(Icons.self_improvement, context.loc.life,
                          Colors.purple, fontSize),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),

                TemplateSection(
                  title: context.loc.trendingQuotes,
                  fetchTemplates: _templateService.fetchRecentTemplates,
                  fontSize: fontSize,
                  onTemplateSelected: _handleTemplateSelection,
                ),

                SizedBox(height: 30),
                Text(
                  "New ✨",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      quoteCard("Everything requires hard work.", fontSize),
                      quoteCard("Success comes from daily efforts.", fontSize),
                      quoteCard("Believe in yourself.", fontSize),
                      quoteCard("Believe in yourself.", fontSize),
                      quoteCard("Believe in yourself.", fontSize),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget quoteCard(String text, double fontSize) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: fontSize - 2)),
      ),
    );
  }

  Widget categoryCard(
      IconData icon, String title, Color color, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 5),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: fontSize - 2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class FontSizeProvider with ChangeNotifier {
  double _fontSize = 14.0;

  double get fontSize => _fontSize;

  void setFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }
}
