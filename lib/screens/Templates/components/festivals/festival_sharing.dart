import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_handler.dart';

class FestivalSharingPage extends StatelessWidget {
  final FestivalPost festival;
  final String userName;
  final String userProfileImageUrl;
  final bool isPaidUser;

  const FestivalSharingPage({
    Key? key,
    required this.festival,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isPaidUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Festival Post'),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview card
                      RepaintBoundary(
                        key: FestivalHandler
                            .festivalSharingImageKey, // Use the different key
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  festival.imageUrl,
                                  width: double.infinity,
                                  height: 400,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 400,
                                      color: Colors.grey[300],
                                      child: Center(
                                        child: Icon(Icons.image_not_supported,
                                            size: 50),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Festival details
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      festival.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // SizedBox(height: 8),
                                    // if (festival.description != null && festival.description!.isNotEmpty)
                                    //   Text(
                                    //     festival.description!,
                                    //     style: GoogleFonts.poppins(
                                    //       fontSize: 14,
                                    //       color: Colors.grey[700],
                                    //     ),
                                    //   ),
                                    SizedBox(height: 16),
                                    if (isPaidUser)
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: userProfileImageUrl
                                                    .isNotEmpty
                                                ? NetworkImage(
                                                    userProfileImageUrl)
                                                : AssetImage(
                                                        'assets/images/profile_placeholder.png')
                                                    as ImageProvider,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            userName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Sharing options title
                      Text(
                        context.loc.sharing_options,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => FestivalHandler.shareFestival(
                            context,
                            festival,
                            userName: userName,
                            userProfileImageUrl: userProfileImageUrl,
                            isPaidUser: isPaidUser,
                          ),
                          icon: Icon(Icons.share),
                          label: Text(
                            isPaidUser
                                ? context.loc.share_with_attribution
                                : context.loc.share,
                            style: GoogleFonts.poppins(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Create button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditScreen(
                                  title: 'Edit Festival Post',
                                  templateImageUrl: festival.imageUrl,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit),
                          label: Text(
                            context.loc.customize,
                            style: GoogleFonts.poppins(),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      if (!isPaidUser) ...[
                        SizedBox(height: 32),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    context.loc.upgrade_to_premium,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                context.loc.premium_sharing_features,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, '/subscription');
                                  },
                                  child: Text(
                                    context.loc.upgrade_now,
                                    style: GoogleFonts.poppins(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
