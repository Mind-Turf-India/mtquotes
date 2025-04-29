// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class GallerySelectionPage extends StatefulWidget {
//   final List<XFile> selectedImages;
//
//   const GallerySelectionPage({
//     Key? key,
//     required this.selectedImages,
//   }) : super(key: key);
//
//   @override
//   State<GallerySelectionPage> createState() => _GallerySelectionPageState();
// }
//
// class _GallerySelectionPageState extends State<GallerySelectionPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Back button at the top left
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Align(
//                 alignment: Alignment.topLeft,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: const Icon(Icons.arrow_back, size: 24),
//                 ),
//               ),
//             ),
//
//             // Grid of images
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: GridView.builder(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 16,
//                     mainAxisSpacing: 16,
//                   ),
//                   itemCount: widget.selectedImages.length,
//                   itemBuilder: (context, index) {
//                     return ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           // The image
//                           Container(
//                             color: Colors.grey[400],
//                             child: Image.file(
//                               File(widget.selectedImages[index].path),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           // Centered number
//                           // Center(
//                           //   child: Text(
//                           //     '${index + 1}',
//                           //     style: const TextStyle(
//                           //       color: Colors.white,
//                           //       fontSize: 24,
//                           //       fontWeight: FontWeight.bold,
//                           //     ),
//                           //   ),
//                           // ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//             // Done button at the bottom
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () async {
//                     // Return the images and add a bool flag to indicate scanner should be launched
//                     Navigator.pop(context, {
//                       'images': widget.selectedImages,
//                       'launchScanner': true
//                     });
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                   ),
//                   child: const Text(
//                     'Done',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }