// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // Changed to this package
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/services.dart';
// import 'package:mtquotes/l10n/app_localization.dart';
// import '../../Templates/unified_model.dart';
//
// class EnhancedPostCard extends StatefulWidget {
//   final UnifiedPost post;
//   final VoidCallback? onEditPressed;
//   final Function(UnifiedPost)? onRatingChanged;
//   final bool showFullActions;
//
//   const EnhancedPostCard({
//     Key? key,
//     required this.post,
//     this.onEditPressed,
//     this.onRatingChanged,
//     this.showFullActions = true,
//   }) : super(key: key);
//
//   @override
//   _EnhancedPostCardState createState() => _EnhancedPostCardState();
// }
//
// class _EnhancedPostCardState extends State<EnhancedPostCard> with SingleTickerProviderStateMixin {
//   bool _isLoading = false;
//   double _aspectRatio = 1.0; // Default aspect ratio
//   bool _imageLoaded = false;
//   final GlobalKey _cardKey = GlobalKey();
//   late AnimationController _animationController;
//   bool _showActionMenu = false;
//   bool _isFavorite = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadImageDimensions();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 200),
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   // Load image dimensions to calculate aspect ratio
//   Future<void> _loadImageDimensions() async {
//     try {
//       final image = NetworkImage(widget.post.imageUrl);
//       final ImageStreamListener listener = ImageStreamListener(
//             (ImageInfo info, bool synchronousCall) {
//           if (mounted) {
//             setState(() {
//               _aspectRatio = info.image.width / info.image.height;
//               _imageLoaded = true;
//             });
//           }
//         },
//         onError: (dynamic exception, StackTrace? stackTrace) {
//           print('Error loading image: $exception');
//           if (mounted) {
//             setState(() {
//               _imageLoaded = true; // Still mark as loaded to avoid infinite loading
//             });
//           }
//         },
//       );
//
//       image.resolve(ImageConfiguration()).addListener(listener);
//     } catch (e) {
//       print('Error determining image aspect ratio: $e');
//       if (mounted) {
//         setState(() {
//           _imageLoaded = true; // Mark as loaded even on error
//         });
//       }
//     }
//   }
//
//   // Toggle favorite status
//   void _toggleFavorite() {
//     setState(() {
//       _isFavorite = !_isFavorite;
//     });
//
//     // Here you would typically call an API to update the favorite status
//     // For example: FavoriteService.toggleFavorite(widget.post.id, _isFavorite);
//
//     // Show confirmation
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(_isFavorite
//             ? 'Added to favorites'
//             : 'Removed from favorites'),
//         duration: Duration(seconds: 1),
//       ),
//     );
//   }
//
//   // Toggle action menu
//   void _toggleActionMenu() {
//     setState(() {
//       _showActionMenu = !_showActionMenu;
//     });
//
//     if (_showActionMenu) {
//       _animationController.forward();
//     } else {
//       _animationController.reverse();
//     }
//   }
//
//   // Capture widget as image
//   Future<Uint8List?> _captureWidgetAsImage() async {
//     try {
//       RenderRepaintBoundary boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//
//       if (byteData != null) {
//         return byteData.buffer.asUint8List();
//       }
//       return null;
//     } catch (e) {
//       print('Error capturing widget: $e');
//       return null;
//     }
//   }
//
//   // Share the post to a specific platform
//   Future<void> _sharePost(BuildContext context, {String? platform}) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       File tempFile;
//
//       // Try to capture the card with UI overlay if applicable
//       if (platform != null && platform != 'direct') {
//         final imageBytes = await _captureWidgetAsImage();
//         if (imageBytes != null) {
//           final tempDir = await getTemporaryDirectory();
//           tempFile = File('${tempDir.path}/shared_post.png');
//           await tempFile.writeAsBytes(imageBytes);
//         } else {
//           // Fallback: download the original image
//           final response = await http.get(Uri.parse(widget.post.imageUrl));
//           if (response.statusCode != 200) {
//             throw Exception('Failed to download image');
//           }
//           final tempDir = await getTemporaryDirectory();
//           tempFile = File('${tempDir.path}/shared_post.jpg');
//           await tempFile.writeAsBytes(response.bodyBytes);
//         }
//       } else {
//         // Direct sharing: download the original image
//         final response = await http.get(Uri.parse(widget.post.imageUrl));
//         if (response.statusCode != 200) {
//           throw Exception('Failed to download image');
//         }
//         final tempDir = await getTemporaryDirectory();
//         tempFile = File('${tempDir.path}/shared_post.jpg');
//         await tempFile.writeAsBytes(response.bodyBytes);
//       }
//
//       // Share based on platform
//       switch (platform) {
//         case 'whatsapp':
//         // For a more complete implementation, you'd use platform-specific plugins
//         // This is a simplified approach for cross-platform compatibility
//           final Uri whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(widget.post.title)}');
//           if (await canLaunchUrl(whatsappUri)) {
//             await launchUrl(whatsappUri);
//           } else {
//             await Share.shareXFiles(
//               [XFile(tempFile.path)],
//               text: widget.post.title,
//               subject: 'Check out this quote!',
//             );
//           }
//           break;
//
//         case 'facebook':
//         // Similarly, for a complete implementation, use platform-specific plugins
//           final Uri facebookUri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://yourapp.com/share')}');
//           if (await canLaunchUrl(facebookUri)) {
//             await launchUrl(facebookUri);
//           } else {
//             await Share.shareXFiles(
//               [XFile(tempFile.path)],
//               text: widget.post.title,
//               subject: 'Check out this quote!',
//             );
//           }
//           break;
//
//         case 'direct':
//         // Download directly to gallery using image_gallery_saver_plus
//           final Uint8List bytes = await tempFile.readAsBytes();
//           final result = await ImageGallerySaverPlus.saveImage(
//               bytes,
//               quality: 100,
//               name: "vaky_quote_${DateTime.now().millisecondsSinceEpoch}"
//           );
//
//           if (result['isSuccess'] != true) {
//             throw Exception('Failed to save image to gallery');
//           }
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Image saved to gallery')),
//           );
//           break;
//
//         default:
//         // Universal share
//           await Share.shareXFiles(
//             [XFile(tempFile.path)],
//             text: widget.post.title,
//             subject: 'Check out this quote!',
//           );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _showActionMenu = false;
//           _animationController.reverse();
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final bool isDarkMode = theme.brightness == Brightness.dark;
//     final Color textColor = isDarkMode ? Colors.white : Colors.black;
//     final Color cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
//     final Color iconColor = isDarkMode ? Colors.white70 : Colors.black87;
//
//     return RepaintBoundary(
//       key: _cardKey,
//       child: Stack(
//         children: [
//           // Main Card
//           Card(
//             margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             elevation: 2,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             color: cardColor,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Post header with title and badge
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           widget.post.title,
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: textColor,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           if (widget.post.isPaid)
//                             Container(
//                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                               margin: EdgeInsets.only(right: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.amber,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 'Premium',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                             ),
//                           // Source badge
//                           Container(
//                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: _getSourceColor(widget.post.source),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               _getSourceLabel(widget.post.source),
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Main image content
//                 GestureDetector(
//                   onTap: widget.onEditPressed,
//                   onDoubleTap: _toggleFavorite,
//                   child: AspectRatio(
//                     aspectRatio: _imageLoaded ? _aspectRatio : 1.5,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: CachedNetworkImage(
//                           imageUrl: widget.post.imageUrl,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) => Container(
//                             color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
//                             child: Center(
//                               child: CircularProgressIndicator(
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   isDarkMode ? Colors.white : Colors.black54,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           errorWidget: (context, url, error) => Container(
//                             color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
//                             child: Center(
//                               child: Icon(Icons.error, color: iconColor),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//
//                 // Action buttons
//                 widget.showFullActions
//                     ? _buildFullActionsRow(context, iconColor, textColor)
//                     : _buildCompactActionsRow(context, iconColor, textColor),
//               ],
//             ),
//           ),
//
//           // Overlay action menu (when expanded)
//           if (_showActionMenu)
//             Positioned.fill(
//               child: GestureDetector(
//                 onTap: _toggleActionMenu, // Close menu on tap outside
//                 child: Container(
//                   color: Colors.black54,
//                   child: FadeTransition(
//                     opacity: _animationController,
//                     child: Center(
//                       child: Card(
//                         color: cardColor,
//                         elevation: 8,
//                         margin: EdgeInsets.all(32),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 context.loc.share,
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: textColor,
//                                 ),
//                               ),
//                               SizedBox(height: 24),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   _buildShareOption(
//                                     context: context,
//                                     icon: Icons.share,
//                                     label: context.loc.share,
//                                     onTap: () => _sharePost(context),
//                                     color: Colors.blue,
//                                   ),
//                                   _buildShareOption(
//                                     context: context,
//                                     svgAsset: 'assets/icons/whatsapp.svg',
//                                     label: 'WhatsApp',
//                                     onTap: () => _sharePost(context, platform: 'whatsapp'),
//                                     color: Color(0xFF25D366), // WhatsApp green
//                                   ),
//                                   _buildShareOption(
//                                     context: context,
//                                     svgAsset: 'assets/icons/facebook.svg',
//                                     label: 'Facebook',
//                                     onTap: () => _sharePost(context, platform: 'facebook'),
//                                     color: Color(0xFF1877F2), // Facebook blue
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 16),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   _buildShareOption(
//                                     context: context,
//                                     icon: Icons.download,
//                                     label: context.loc.save,
//                                     onTap: () => _sharePost(context, platform: 'direct'),
//                                     color: Colors.green,
//                                   ),
//                                   _buildShareOption(
//                                     context: context,
//                                     svgAsset: 'assets/icons/instagram.svg',
//                                     label: 'Instagram',
//                                     onTap: () => _sharePost(context, platform: 'instagram'),
//                                     color: Color(0xFFE1306C), // Instagram gradient approximation
//                                   ),
//                                   _buildShareOption(
//                                     context: context,
//                                     icon: Icons.copy,
//                                     label: 'context.loc.copy',
//                                     onTap: () {
//                                       Clipboard.setData(ClipboardData(text: widget.post.title));
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(content: Text('Text copied to clipboard')),
//                                       );
//                                       _toggleActionMenu();
//                                     },
//                                     color: Colors.orange,
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 24),
//                               TextButton(
//                                 onPressed: _toggleActionMenu,
//                                 child: Text(
//                                   context.loc.cancel,
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.blue,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//           // Loading overlay
//           if (_isLoading)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black45,
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // Build full action buttons row (for larger screens)
//   Widget _buildFullActionsRow(BuildContext context, Color iconColor, Color textColor) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildActionButton(
//             icon: Icons.share,
//             label: context.loc.share,
//             onPressed: _toggleActionMenu,
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//           _buildActionButton(
//             icon: Icons.edit,
//             label: context.loc.editimage,
//             onPressed: widget.onEditPressed,
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//           _buildActionButton(
//             icon: Icons.download,
//             label: context.loc.save,
//             onPressed: () => _sharePost(context, platform: 'direct'),
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//           _buildActionButton(
//             svgPath: 'assets/icons/whatsapp.svg',
//             label: 'WhatsApp',
//             onPressed: () => _sharePost(context, platform: 'whatsapp'),
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//           _buildActionButton(
//             svgPath: 'assets/icons/facebook.svg',
//             label: 'Facebook',
//             onPressed: () => _sharePost(context, platform: 'facebook'),
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Build compact action buttons row (for smaller screens)
//   Widget _buildCompactActionsRow(BuildContext context, Color iconColor, Color textColor) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildActionButton(
//             icon: Icons.share,
//             label: context.loc.share,
//             onPressed: _toggleActionMenu,
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//           _buildActionButton(
//             icon: Icons.edit,
//             label: context.loc.editimage,
//             onPressed: widget.onEditPressed,
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//           _buildActionButton(
//             icon: Icons.download,
//             label: context.loc.save,
//             onPressed: () => _sharePost(context, platform: 'direct'),
//             iconColor: iconColor,
//             textColor: textColor,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper method to build action buttons
//   Widget _buildActionButton({
//     IconData? icon,
//     String? svgPath,
//     required String label,
//     required VoidCallback? onPressed,
//     required Color iconColor,
//     required Color textColor,
//   }) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (icon != null)
//               Icon(icon, color: iconColor, size: 20)
//             else if (svgPath != null)
//               SvgPicture.asset(
//                 svgPath,
//                 width: 20,
//                 height: 20,
//                 color: iconColor,
//               ),
//             SizedBox(height: 4),
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 10,
//                 color: textColor.withOpacity(0.8),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper method to build share options in the expanded menu
//   Widget _buildShareOption({
//     required BuildContext context,
//     IconData? icon,
//     String? svgAsset,
//     required String label,
//     required VoidCallback onTap,
//     required Color color,
//   }) {
//     final ThemeData theme = Theme.of(context);
//     final bool isDarkMode = theme.brightness == Brightness.dark;
//     final Color textColor = isDarkMode ? Colors.white : Colors.black;
//
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         width: 80,
//         padding: EdgeInsets.symmetric(vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 // Light background that contrasts with both dark and light themes
//                 color: color.withOpacity(0.1), // Very light tint of the icon color
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Center(
//                 child: icon != null
//                     ? Icon(
//                   icon,
//                   color: color, // This makes the icon appear in its proper color
//                   size: 30,
//                 )
//                     : svgAsset != null
//                     ? SvgPicture.asset(
//                   svgAsset,
//                   width: 30,
//                   height: 30,
//                   // For Flutter 3.0 and above:
//                   colorFilter: ColorFilter.mode(
//                     color,
//                     BlendMode.srcIn,
//                   ),
//                   // For older Flutter versions:
//                   // color: color,
//                 )
//                     : SizedBox(),
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: textColor,
//               ),
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   // Helper method to get source color
//   Color _getSourceColor(PostSource source) {
//     switch (source) {
//       case PostSource.qotd:
//         return Colors.blue;
//       case PostSource.trending:
//         return Colors.purple;
//       case PostSource.totd:
//         return Colors.green;
//       case PostSource.festival:
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   // Helper method to get source label
//   String _getSourceLabel(PostSource source) {
//     switch (source) {
//       case PostSource.qotd:
//         return 'QOTD';
//       case PostSource.trending:
//         return 'Trending';
//       case PostSource.totd:
//         return 'For You';
//       case PostSource.festival:
//         return 'Festival';
//       default:
//         return '';
//     }
//   }
// }