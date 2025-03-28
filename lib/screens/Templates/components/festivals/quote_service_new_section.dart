// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
// import 'dart:async';

// class QuoteService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Get quotes for the New Section
//   Stream<List<QuoteTemplate>> getNewSectionQuotes() {
//     // Create a StreamController to handle the quote stream
//     final controller = StreamController<List<QuoteTemplate>>();
    
//     // Listen for active festivals and update quotes accordingly
//     Timer.periodic(Duration(hours: 1), (_) => _updateQuotes(controller));
//     // Initial update
//     _updateQuotes(controller);
    
//     return controller.stream;
//   }
  
//   // Update quotes based on active festivals
//   Future<void> _updateQuotes(StreamController<List<QuoteTemplate>> controller) async {
//     try {
//       final activeFestivalIds = await getActiveFestivalIds();
      
//       if (activeFestivalIds.isNotEmpty) {
//         // If there are active festivals, get quotes for those festivals
//         _firestore
//             .collection('quote_templates')
//             .where('festivalId', whereIn: activeFestivalIds.length > 10 ? 
//                 activeFestivalIds.sublist(0, 10) : activeFestivalIds) // Firestore limit: whereIn has max 10 values
//             .orderBy('createdAt', descending: true)
//             .limit(20)
//             .snapshots()
//             .listen((snapshot) {
//               controller.add(_mapQueryToQuotes(snapshot));
//             }, onError: (error) {
//               print('Error getting festival quotes: $error');
//               controller.addError(error);
//             });
//       } else {
//         // If no active festivals, get general quotes
//         _firestore
//             .collection('quote_templates')
//             .where('festivalId', isEqualTo: null)
//             .orderBy('createdAt', descending: true)
//             .limit(20)
//             .snapshots()
//             .listen((snapshot) {
//               controller.add(_mapQueryToQuotes(snapshot));
//             }, onError: (error) {
//               print('Error getting general quotes: $error');
//               controller.addError(error);
//             });
//       }
//     } catch (e) {
//       print('Error in _updateQuotes: $e');
//       controller.addError(e);
//     }
//   }
  
//   // Helper method to map query snapshot to quotes list
//   List<QuoteTemplate> _mapQueryToQuotes(QuerySnapshot snapshot) {
//     return snapshot.docs.map((doc) => QuoteTemplate.fromFirestore(doc)).toList();
//   }
  
//   // Get IDs of currently active festivals
//   Future<List<String>> getActiveFestivalIds() async {
//     try {
//       final now = DateTime.now();
//       final festivalsSnapshot = await _firestore.collection('festivals').get();
      
//       List<String> activeFestivalIds = [];
//       for (var doc in festivalsSnapshot.docs) {
//         final data = doc.data();
//         // Check if 'festivalDate' key exists (matches your festival model)
//         final DateTime festivalDate = data.containsKey('festivalDate') ? 
//             (data['festivalDate'] as Timestamp).toDate() : 
//             (data['date'] as Timestamp).toDate();
            
//         final int showDaysBefore = data['showDaysBefore'] ?? 7;
        
//         final DateTime showFromDate = festivalDate.subtract(Duration(days: showDaysBefore));
        
//         if (now.isAfter(showFromDate) && now.isBefore(festivalDate.add(Duration(days: 1)))) {
//           activeFestivalIds.add(doc.id);
//         }
//       }
      
//       return activeFestivalIds;
//     } catch (e) {
//       print('Error getting active festival IDs: $e');
//       return [];
//     }
//   }
  
//   // Get quotes by specific festival ID
//   Stream<List<QuoteTemplate>> getQuotesByFestival(String festivalId) {
//     return _firestore
//         .collection('quote_templates')
//         .where('festivalId', isEqualTo: festivalId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map(_mapQueryToQuotes);
//   }
  
//   // Get trending quotes
//   Stream<List<QuoteTemplate>> getTrendingQuotes() {
//     return _firestore
//         .collection('quote_templates')
//         .orderBy('likeCount', descending: true)
//         .limit(20)
//         .snapshots()
//         .map(_mapQueryToQuotes);
//   }
// }