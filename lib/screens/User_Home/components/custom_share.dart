// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
//
// class CustomShareBottomSheet extends StatelessWidget {
//   final String imageUrl;
//   final String title;
//   final Function onClose;
//
//   const CustomShareBottomSheet({
//     Key? key,
//     required this.imageUrl,
//     required this.title,
//     required this.onClose,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Share with Friends',
//             style: GoogleFonts.poppins(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 25),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/whatsapp.png',
//                   label: 'WhatsApp',
//                   onTap: () => _shareToWhatsApp(context),
//                 ),
//                 SizedBox(width: 15),
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/whatsapp_status.png',
//                   label: 'WhatsApp\nStatus',
//                   onTap: () => _shareToWhatsAppStatus(context),
//                 ),
//                 SizedBox(width: 15),
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/whatsapp_group.png',
//                   label: 'WhatsApp\nGroup',
//                   onTap: () => _shareToWhatsAppGroup(context),
//                 ),
//                 SizedBox(width: 15),
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/instagram.png',
//                   label: 'Instagram',
//                   onTap: () => _shareToInstagram(context),
//                 ),
//                 SizedBox(width: 15),
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/facebook.png',
//                   label: 'Facebook\nFeed',
//                   onTap: () => _shareToFacebookFeed(context),
//                 ),
//                 SizedBox(width: 15),
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/facebook_story.png',
//                   label: 'Facebook\nStory',
//                   onTap: () => _shareToFacebookStory(context),
//                 ),
//                 SizedBox(width: 15),
//                 _buildShareOption(
//                   context: context,
//                   imagePath: 'assets/icons/more.png',
//                   label: 'Other',
//                   onTap: () => _shareToOthers(context),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 30),
//           Text(
//             'Share this via link',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 15),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   'Https://',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 16,
//                   ),
//                 ),
//                 Spacer(),
//                 IconButton(
//                   icon: Icon(Icons.copy, color: Colors.grey[600]),
//                   onPressed: () => _copyShareLink(context),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildShareOption({
//     required BuildContext context,
//     required String imagePath,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(9),
//               child: Image.asset(
//                 imagePath,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 12,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Fix for Instagram sharing
//   Future<void> _shareToInstagram(BuildContext context) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/instagram_share.jpg');
//
//       // Download the image
//       final response = await http.get(Uri.parse(imageUrl));
//       await file.writeAsBytes(response.bodyBytes);
//
//       // Close the bottom sheet
//       onClose();
//
//       if (Platform.isAndroid) {
//         // Try to launch Instagram's share intent directly
//         final uri = Uri.parse("instagram://camera");
//         bool launched = false;
//
//         try {
//           launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Could not launch Instagram: $e");
//         }
//
//         if (launched) {
//           // Instagram was launched, now wait before sharing
//           await Future.delayed(Duration(seconds: 1));
//
//           // Share image with generic share sheet, which will show Instagram as option
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           // Instagram not installed, use generic sharing
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         }
//       } else if (Platform.isIOS) {
//         // On iOS, try a similar approach
//         final uri = Uri.parse("instagram://");
//         bool launched = false;
//
//         try {
//           launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Could not launch Instagram on iOS: $e");
//         }
//
//         if (launched) {
//           await Future.delayed(Duration(seconds: 1));
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         }
//       } else {
//         // For other platforms
//         await Share.shareXFiles(
//           [XFile(file.path)],
//           text: title,
//         );
//       }
//     } catch (e) {
//       print("Error sharing to Instagram: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing to Instagram: $e')),
//       );
//     }
//   }
//
//   // Fix for Facebook sharing
//   Future<void> _shareToFacebookFeed(BuildContext context) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/facebook_share.jpg');
//
//       // Download the image
//       final response = await http.get(Uri.parse(imageUrl));
//       await file.writeAsBytes(response.bodyBytes);
//
//       // Close the bottom sheet
//       onClose();
//
//       if (Platform.isAndroid) {
//         // Try to launch Facebook app directly
//         final uri = Uri.parse("fb://feed");
//         bool launched = false;
//
//         try {
//           launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Could not launch Facebook: $e");
//         }
//
//         if (launched) {
//           // Facebook was launched, now share the image
//           await Future.delayed(Duration(seconds: 1));
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           // Facebook not installed, try web or generic sharing
//           final webUri = Uri.parse("https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://yourdomain.com/share')}&quote=${Uri.encodeComponent(title)}");
//
//           try {
//             launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
//           } catch (e) {
//             print("Could not launch Facebook web: $e");
//           }
//
//           if (!launched) {
//             // If web sharing fails too, use generic sharing
//             await Share.shareXFiles(
//               [XFile(file.path)],
//               text: title,
//             );
//           }
//         }
//       } else if (Platform.isIOS) {
//         // On iOS
//         final uri = Uri.parse("fb://");
//         bool launched = false;
//
//         try {
//           launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Could not launch Facebook on iOS: $e");
//         }
//
//         if (launched) {
//           await Future.delayed(Duration(seconds: 1));
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         }
//       } else {
//         // For other platforms
//         await Share.shareXFiles(
//           [XFile(file.path)],
//           text: title,
//         );
//       }
//     } catch (e) {
//       print("Error sharing to Facebook: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing to Facebook: $e')),
//       );
//     }
//   }
//
//   // Facebook Story sharing
//   Future<void> _shareToFacebookStory(BuildContext context) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/facebook_story.jpg');
//
//       // Download the image
//       final response = await http.get(Uri.parse(imageUrl));
//       await file.writeAsBytes(response.bodyBytes);
//
//       // Close the bottom sheet
//       onClose();
//
//       if (Platform.isAndroid || Platform.isIOS) {
//         // Try to launch Facebook app directly to stories
//         final uri = Uri.parse("fb://stories");
//         bool launched = false;
//
//         try {
//           launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Could not launch Facebook Stories: $e");
//         }
//
//         if (launched) {
//           // Wait a moment for app to open
//           await Future.delayed(Duration(seconds: 1));
//
//           // Then share
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           // If stories feature unavailable, try regular feed
//           await _shareToFacebookFeed(context);
//         }
//       } else {
//         // For other platforms
//         await Share.shareXFiles(
//           [XFile(file.path)],
//           text: title,
//         );
//       }
//     } catch (e) {
//       print("Error sharing to Facebook Story: $e");
//       // Fallback to Facebook feed
//       await _shareToFacebookFeed(context);
//     }
//   }
//
//   // Keep the existing methods for WhatsApp sharing
//   Future<void> _shareToWhatsApp(BuildContext context) async {
//     _shareWithApp(context, 'com.whatsapp');
//   }
//
//   Future<void> _shareToWhatsAppStatus(BuildContext context) async {
//     _shareWithApp(context, 'com.whatsapp');
//   }
//
//   Future<void> _shareToWhatsAppGroup(BuildContext context) async {
//     _shareWithApp(context, 'com.whatsapp');
//   }
//
//   Future<void> _shareToOthers(BuildContext context) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/share_image.jpg');
//
//       // Download the image
//       final response = await http.get(Uri.parse(imageUrl));
//       await file.writeAsBytes(response.bodyBytes);
//
//       // Close dialog
//       onClose();
//
//       // Show regular share sheet
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         text: title,
//         subject: 'Check out this quote!',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing: $e')),
//       );
//     }
//   }
//
//   Future<void> _shareWithApp(
//       BuildContext context,
//       String packageName,
//       {bool status = false, bool group = false, bool story = false}
//       ) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/share_image.jpg');
//
//       // Download the image
//       final response = await http.get(Uri.parse(imageUrl));
//       await file.writeAsBytes(response.bodyBytes);
//
//       // Close dialog
//       onClose();
//
//       if (Platform.isAndroid) {
//         // For WhatsApp on Android
//         String uri = "whatsapp://send?text=${Uri.encodeComponent(title)}";
//
//         if (status) {
//           uri = "whatsapp://status";
//         } else if (group) {
//           uri = "whatsapp://send?text=${Uri.encodeComponent(title)}";
//         }
//
//         bool launched = false;
//         try {
//           launched = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Error launching WhatsApp: $e");
//         }
//
//         if (launched) {
//           await Future.delayed(Duration(milliseconds: 1000));
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         }
//       } else if (Platform.isIOS) {
//         // For iOS
//         String uri = "whatsapp://app";
//
//         if (status) {
//           uri = "whatsapp://status";
//         }
//
//         bool launched = false;
//         try {
//           launched = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
//         } catch (e) {
//           print("Error launching WhatsApp on iOS: $e");
//         }
//
//         if (launched) {
//           await Future.delayed(Duration(milliseconds: 1000));
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         } else {
//           await Share.shareXFiles(
//             [XFile(file.path)],
//             text: title,
//           );
//         }
//       } else {
//         // For other platforms
//         await Share.shareXFiles(
//           [XFile(file.path)],
//           text: title,
//         );
//       }
//     } catch (e) {
//       print("Error in _shareWithApp: $e");
//       _shareToOthers(context);
//     }
//   }
//
//   void _copyShareLink(BuildContext context) {
//     // Create a dummy link or actual link if available
//     final String linkToShare = "https://yourdomain.com/share/quote123";
//
//     Clipboard.setData(ClipboardData(text: linkToShare));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Link copied to clipboard')),
//     );
//   }
// }