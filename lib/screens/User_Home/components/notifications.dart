import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/User_Home/components/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: Colors.grey[400],
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
                  "Notifications",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'clear') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Clear All Notifications"),
                          content: Text("Are you sure you want to clear all notifications?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("CANCEL"),
                            ),
                            TextButton(
                              onPressed: () {
                                NotificationService.instance.clearAllNotifications();
                                Navigator.pop(context);
                              },
                              child: Text("CLEAR"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear',
                      child: Text("Clear All"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.bellOff,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No notifications yet",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
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
                                  color: selectedIndex == index ? Colors.grey[100] : Colors.white,
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
                                                        fontSize: 16,
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
                                                  fontSize: 16,
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              notification.body,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _getFormattedTime(notification.timestamp),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
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
                                            color: Colors.black54,
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