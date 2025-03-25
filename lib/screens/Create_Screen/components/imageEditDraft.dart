// import 'dart:convert';

// class ImageEditDraft {
//   final String id;
//   final String originalImagePath;
//   final String editedImagePath;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   String? title;

//   ImageEditDraft({
//     required this.id,
//     required this.originalImagePath,
//     required this.editedImagePath,
//     required this.createdAt,
//     required this.updatedAt,
//     this.title,
//   });

//   // Create a copy of this draft with new values
//   ImageEditDraft copyWith({
//     String? id,
//     String? originalImagePath,
//     String? editedImagePath,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     String? title,
//   }) {
//     return ImageEditDraft(
//       id: id ?? this.id,
//       originalImagePath: originalImagePath ?? this.originalImagePath,
//       editedImagePath: editedImagePath ?? this.editedImagePath,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       title: title ?? this.title,
//     );
//   }

//   // Convert draft to JSON for storageg
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'originalImagePath': originalImagePath,
//       'editedImagePath': editedImagePath,
//       'createdAt': createdAt.millisecondsSinceEpoch,
//       'updatedAt': updatedAt.millisecondsSinceEpoch,
//       'title': title,
//     };
//   }

//   // Create draft from JSON data
//   factory ImageEditDraft.fromJson(Map<String, dynamic> json) {
//     return ImageEditDraft(
//       id: json['id'],
//       originalImagePath: json['originalImagePath'],
//       editedImagePath: json['editedImagePath'],
//       createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
//       updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
//       title: json['title'],
//     );
//   }
// }