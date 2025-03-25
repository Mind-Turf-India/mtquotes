// import 'package:mtquotes/screens/Create_Screen/components/imageEditDraft.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'dart:io';

// class DraftService {
//   static const String _draftsKey = 'image_edit_drafts';
  
//   Future<List<ImageEditDraft>> getAllDrafts() async {
//     final prefs = await SharedPreferences.getInstance();
//     final List<String> draftsJson = prefs.getStringList(_draftsKey) ?? [];
    
//     return draftsJson
//         .map((json) => ImageEditDraft.fromJson(jsonDecode(json)))
//         .toList();
//   }
  
//   Future<ImageEditDraft?> getDraft(String id) async {
//     final drafts = await getAllDrafts();
//     try {
//       return drafts.firstWhere((draft) => draft.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
  
//   Future<void> saveDraft(ImageEditDraft draft) async {
//     final prefs = await SharedPreferences.getInstance();
//     final List<ImageEditDraft> drafts = await getAllDrafts();
    
//     // Remove existing draft with same ID if it exists
//     drafts.removeWhere((d) => d.id == draft.id);
    
//     // Add the new/updated draft
//     drafts.add(draft);
    
//     // Save back to SharedPreferences
//     final List<String> draftsJson = drafts
//         .map((draft) => jsonEncode(draft.toJson()))
//         .toList();
    
//     await prefs.setStringList(_draftsKey, draftsJson);
//   }
  
//   Future<void> deleteDraft(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final List<ImageEditDraft> drafts = await getAllDrafts();
    
//     // Check if draft exists before attempting to delete
//     final index = drafts.indexWhere((draft) => draft.id == id);
    
//     if (index != -1) {
//       // Get the draft to delete
//       final draftToDelete = drafts[index];
      
//       // Delete the image file
//       try {
//         await File(draftToDelete.editedImagePath).delete();
//       } catch (e) {
//         print('Error deleting edited image: $e');
//       }
      
//       // Remove from the list
//       drafts.removeAt(index);
      
//       // Save back to SharedPreferences
//       final List<String> draftsJson = drafts
//           .map((draft) => jsonEncode(draft.toJson()))
//           .toList();
      
//       await prefs.setStringList(_draftsKey, draftsJson);
//     }
//   }
// }