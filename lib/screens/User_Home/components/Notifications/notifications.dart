import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/User_Home/components/Notifications/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../../l10n/app_localization.dart';

class NotificationsSheet extends StatefulWidget {
  @override
  _NotificationsSheetState createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  int? selectedIndex;
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // Listen for new notifications
    NotificationService.instance.notificationsStream.listen((updatedNotifications) {
      if (mounted) {
        setState(() {
          notifications = updatedNotifications;
          isLoading = false;
        });
      }
    });
  }

  Future<void> _loadNotifications() async {
    await Future.delayed(Duration(milliseconds: 300));
    setState(() {
      notifications = NotificationService.instance.notifications;
      isLoading = false;
    });
  }

  String _getFormattedTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('h:mm a, MMM d, yyyy').format(timestamp);
    } else {
      return timeago.format(timestamp);
    }
  }

  String _getInitials(String title) {
    if (title.isEmpty) return "N";

    List<String> words = title.split(" ");
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }

  Color _getAvatarColor(String id) {
    // Generate a consistent color based on the notification ID
    final int hashCode = id.hashCode;
    final List<Color> colors = [
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.red[300]!,
      Colors.teal[300]!,
    ];

    return colors[hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.loc.notifications,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.getIconColor(isDarkMode)),
                  onSelected: (value) {
                    if (value == 'clear') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.getBackgroundColor(isDarkMode),
                          title: Text(
                            context.loc.clearAllNotifications,
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize: fontSize,
                            ),
                          ),
                          content: Text(
                            context.loc.confirmClearNotifications,
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize: fontSize - 2,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                context.loc.cancel,
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                NotificationService.instance.clearAllNotifications();
                                Navigator.pop(context);
                              },
                              child: Text(
                                context.loc.clear,
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(
                        context.loc.clearAll,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDarkMode),
                          fontSize: fontSize - 2,
                        ),
                      ),
                    ),
                  ],
                  color: AppColors.getBackgroundColor(isDarkMode),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : notifications.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bellOff,
                    size: 48,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    context.loc.noNotificationsYet,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppColors.primaryBlue,
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    background: Container(
                      color: Colors.red[400],
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(
                        LucideIcons.trash2,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      NotificationService.instance.deleteNotification(notification.id);
                    },
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });

                        // Mark notification as read
                        NotificationService.instance.markAsRead(notification.id);

                        // Handle notification tap
                        if (notification.data.isNotEmpty) {
                          // Navigate based on notification data
                          // For example:
                          if (notification.data['type'] == 'chat') {
                            // Navigate to chat screen
                            // Navigator.push(...);
                          }
                        }
                      },
                      child: Container(
                        color: selectedIndex == index
                            ? (isDarkMode ? Colors.grey[800] : Colors.grey[100])
                            : AppColors.getBackgroundColor(isDarkMode),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _getAvatarColor(notification.id),
                              child: notification.imageUrl != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.network(
                                  notification.imageUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      _getInitials(notification.title),
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSize - 2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              )
                                  : Text(
                                _getInitials(notification.title),
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextColor(isDarkMode),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    notification.body,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSize - 2,
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _getFormattedTime(notification.timestamp),
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSize - 4,
                                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Delete button
                            GestureDetector(
                              onTap: () {
                                NotificationService.instance.deleteNotification(notification.id);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, top: 4),
                                child: Icon(
                                  LucideIcons.trash,
                                  color: isDarkMode ? Colors.grey[400] : Colors.black54,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}