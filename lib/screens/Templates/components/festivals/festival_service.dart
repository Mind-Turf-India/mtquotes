import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';

// Define Festival model class
class Festival {
  final String id;
  final String name;
  final DateTime date;
  final int showDaysBefore;
  final DateTime createdAt;
  final List<FestivalTemplate> templates; // New field

  Festival({
    required this.id,
    required this.name,
    required this.date,
    required this.showDaysBefore,
    required this.createdAt,
    this.templates = const [],
  });

  factory Festival.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse templates
    List<FestivalTemplate> templatesList = [];
    if (data['templates'] != null) {
      for (var template in data['templates']) {
        templatesList.add(FestivalTemplate.fromMap(template));
      }
    }
    
    return Festival(
      id: doc.id,
      name: data['name'] ?? '',
      date: (data['festivalDate'] as Timestamp).toDate(),
      showDaysBefore: data['showDaysBefore'] ?? 7,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      templates: templatesList,
    );
  }
}


class FestivalTemplate {
  final String id;
  final String imageUrl;
  final bool isPaid;

  FestivalTemplate({
    required this.id,
    required this.imageUrl,
    this.isPaid = false,
  });

  factory FestivalTemplate.fromMap(Map<String, dynamic> map) {
    return FestivalTemplate(
      id: map['id'] ?? '',
      imageUrl: map['imageURL'] ?? '',
      isPaid: map['isPaid'] ?? false,
    );
  }
}


class FestivalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  
 // Get templates for a specific festival
  List<FestivalTemplate> getTemplatesForFestival(Festival festival) {
    return festival.templates;
  }

  // Get specific template by ID
  FestivalTemplate? getTemplateById(Festival festival, String templateId) {
    try {
      return festival.templates.firstWhere(
        (template) => template.id == templateId,
      );
    } catch (e) {
      print('Template not found: $e');
      return null;
    }
  }
  

  // Check if user is subscribed
  Future<bool> isUserSubscribed() async {
    try {
      if (_auth.currentUser == null) return false;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      return userDoc.exists && (userDoc.data() as Map<String, dynamic>)['isSubscribed'] == true;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  // Fetch upcoming festivals
  Future<List<Festival>> fetchUpcomingFestivals() async {
    try {
      // Get current date
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .where('festivalDate', isGreaterThanOrEqualTo: startOfDay)
          .orderBy('festivalDate', descending: false)
          .limit(10)
          .get();

      List<Festival> festivals = snapshot.docs
          .map((doc) => Festival.fromFirestore(doc))
          .toList();

      return festivals;
    } catch (e) {
      print('Error fetching upcoming festivals: $e');
      return [];
    }
  }

  // Fetch recent festival posts
  // Fetch recent festival posts
Future<List<Festival>> fetchRecentFestivalPosts() async {
  try {
    // Get current date
    final DateTime now = DateTime.now();
    
    // Get all festivals
    QuerySnapshot snapshot = await _firestore
        .collection('festivals')
        .orderBy('festivalDate')
        .get();

    // Filter festivals that should be active now
    List<Festival> festivals = [];
    
    for (var doc in snapshot.docs) {
      final festival = Festival.fromFirestore(doc);
      
      // Calculate the date when the festival should start showing
      final DateTime showFromDate = festival.date.subtract(Duration(days: festival.showDaysBefore));
      
      // Only include festivals that should be shown today
      if (now.isAfter(showFromDate) || now.isAtSameMomentAs(showFromDate)) {
        if (now.isBefore(festival.date.add(const Duration(days: 1)))) {
          festivals.add(festival);
        }
      }
    }

    return festivals;
  } catch (e) {
    print('Error fetching recent festivals: $e');
    return [];
  }
}
  // Fetch trending festival posts
  Future<List<Festival>> fetchTrendingFestivalPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .limit(10)
          .get();

      List<Festival> festivals = snapshot.docs
          .map((doc) => Festival.fromFirestore(doc))
          .toList();

      return festivals;
    } catch (e) {
      print('Error fetching trending festivals: $e');
      return [];
    }
  }

  // Fetch festivals by category
  Future<List<Festival>> fetchFestivalsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('festivals')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      List<Festival> festivals = snapshot.docs
          .map((doc) => Festival.fromFirestore(doc))
          .toList();

      return festivals;
    } catch (e) {
      print('Error fetching festivals by category: $e');
      return [];
    }
  }

  // Get active festivals that should be shown today
  Future<List<Festival>> getActiveFestivals() async {
    try {
      final DateTime now = DateTime.now();
      final snapshot = await _firestore.collection('festivals').get();
      
      List<Festival> activeFestivals = [];
      for (var doc in snapshot.docs) {
        final festival = Festival.fromFirestore(doc);
        final DateTime showFromDate = festival.date.subtract(Duration(days: festival.showDaysBefore));
        
        // Check if today is within the active window for the festival
        if (now.isAfter(showFromDate) && now.isBefore(festival.date.add(Duration(days: 1)))) {
          activeFestivals.add(festival);
        }
      }
      
      return activeFestivals;
    } catch (e) {
      print('Error fetching active festivals: $e');
      return [];
    }
  }
  
  // Find the next upcoming festival
  Future<Festival?> getNextFestival() async {
    try {
      final DateTime now = DateTime.now();
      final snapshot = await _firestore.collection('festivals')
          .where('festivalDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('festivalDate')
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) return null;
      
      return Festival.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error fetching next festival: $e');
      return null;
    }
  }
}