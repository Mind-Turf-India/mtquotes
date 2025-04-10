import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String notificationType; // Add notification type field
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.timestamp,
    required this.notificationType, // Required field
    this.isRead = false,
  });

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    // Determine notification type from message
    String notificationType = 'general';
    if (message.data.containsKey('type')) {
      notificationType = message.data['type'];
    }

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      notificationType: notificationType,
      isRead: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'notificationType': notificationType,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      timestamp: DateTime.parse(json['timestamp']),
      notificationType: json['notificationType'] ?? 'general',
      isRead: json['isRead'] ?? false,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);

  // Save the notification even when app is in background
  await NotificationService.instance
      .saveNotification(NotificationModel.fromRemoteMessage(message));
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  String? _currentUserId;
  bool _isPermissionRequested = false;

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  // Stream controller for notifications
  final _notificationsStreamController =
  StreamController<List<NotificationModel>>.broadcast();

  // Stream for unread notifications count
  final _unreadCountStreamController = StreamController<int>.broadcast();

  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsStreamController.stream;

  Stream<int> get unreadCountStream => _unreadCountStreamController.stream;

  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // This method initializes everything EXCEPT permission requests
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup local notifications
    await setupFlutterNotifications();

    // Load saved notifications
    if (_currentUserId != null) {
      await loadSavedNotifications();
    } else {
      // Clear notifications if no user is logged in
      _notifications = [];
      _notificationsStreamController.add(_notifications);
      _unreadCountStreamController.add(0);
    }

    // Setup message handlers
    await _setupMessageHandlers();

    // Get FCM token but don't request permissions yet
    final token = await _messaging.getAPNSToken();
    if (token != null) {
      await _saveToken(token);
    }

    setupTokenRefresh();
  }

  // NEW METHOD: Call this after user logs in
  Future<void> requestPermissions() async {
    if (_isPermissionRequested) return; // Don't request multiple times

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
    _isPermissionRequested = true;

    // After permissions, refresh and save token
    await refreshAndSaveToken();

    // Subscribe to topics
    await _subscribeToTopics();
  }

  Future<void> _subscribeToTopics() async {
    // Subscribe to all topics from your Firebase Cloud Functions
    await _messaging.subscribeToTopic('qotd');
    await _messaging.subscribeToTopic('totd');
    await _messaging.subscribeToTopic('festivals');

    print('Subscribed to notification topics');
  }

  Future<void> refreshAndSaveToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    print('FCM Token: $token');

    // Save the token to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    // Send token to your backend
    await _sendTokenToServer(token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<void> _sendTokenToServer(String? token) async {
    if (token == null) return;

    // Get the current user ID from your auth service
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    try {
      // Replace with your actual API endpoint
      final response = await http.post(
        Uri.parse('https://your-api-endpoint/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('Token successfully registered on server');
      } else {
        print('Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  Future<String?> _getCurrentUserId() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // android setup
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // same as in the Cloud Function
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // ios setup
    final initializationSettingsDarwin = const DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // flutter notification setup
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        final payload = details.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload);
            _handleNotificationTap(data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    String? imageUrl =
        notification?.android?.imageUrl ?? notification?.apple?.imageUrl;

    if (notification != null) {
      BigPictureStyleInformation? bigPictureStyle;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        print('image url fetched');
        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(
              imageUrl), // This may need a proper image loader
          largeIcon: FilePathAndroidBitmap(imageUrl),
          contentTitle: notification.title,
          summaryText: notification.body,
        );
      }

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
            'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: bigPictureStyle, // Attach the style
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Foreground message
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);

      // Save the notification
      saveNotification(NotificationModel.fromRemoteMessage(message));
    });

    // Background message
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleBackgroundMessage(message);
    });

    // Opened app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Save the notification if it's not already saved
    saveNotification(NotificationModel.fromRemoteMessage(message));

    // Additional handling based on notification type
    _handleNotificationTap(message.data);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle notification tap based on data
    // For example, navigate to specific screen based on notification type
    if (data['type'] == 'qotd') {
      // Navigate to QOTD screen
    } else if (data['type'] == 'totd') {
      // Navigate to TOTD screen
    } else if (data['type'] == 'festivals') {
      // Navigate to Festivals screen
    }
  }

  // Methods to manage notifications
  Future<void> saveNotification(NotificationModel notification) async {
    // Check if notification with same ID already exists
    final existingIndex =
    _notifications.indexWhere((n) => n.id == notification.id);

    if (existingIndex >= 0) {
      // Update existing notification
      _notifications[existingIndex] = notification;
    } else {
      // Add new notification
      _notifications.insert(0, notification);
    }

    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Notify listeners
    _notificationsStreamController.add(_notifications);
    _unreadCountStreamController.add(unreadCount);

    // Save to persistent storage
    await _saveNotificationsToStorage();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;

      // Notify listeners
      _notificationsStreamController.add(_notifications);
      _unreadCountStreamController.add(unreadCount);

      // Update persistent storage
      await _saveNotificationsToStorage();
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (final notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        changed = true;
      }
    }

    if (changed) {
      // Notify listeners
      _notificationsStreamController.add(_notifications);
      _unreadCountStreamController.add(0);

      // Update persistent storage
      await _saveNotificationsToStorage();
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((notification) => notification.id == id);

    // Notify listeners
    _notificationsStreamController.add(_notifications);
    _unreadCountStreamController.add(unreadCount);

    // Update persistent storage
    await _saveNotificationsToStorage();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();

    // Notify listeners
    _notificationsStreamController.add(_notifications);
    _unreadCountStreamController.add(0);

    // Clear from persistent storage
    await _saveNotificationsToStorage();
  }

  Future<void> loadSavedNotifications() async {
    try {
      final userId = _currentUserId;

      // If no user is logged in, don't load any notifications
      if (userId == null) {
        _notifications = [];
        _notificationsStreamController.add(_notifications);
        _unreadCountStreamController.add(0);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId'; // User-specific key
      final savedNotifications = prefs.getStringList(key) ?? [];

      _notifications = savedNotifications
          .map((notificationJson) =>
          NotificationModel.fromJson(json.decode(notificationJson)))
          .toList();

      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Notify listeners
      _notificationsStreamController.add(_notifications);
      _unreadCountStreamController.add(unreadCount);
    } catch (e) {
      print('Error loading notifications: $e');
      // Initialize with empty list on error
      _notifications = [];
      _notificationsStreamController.add(_notifications);
      _unreadCountStreamController.add(0);
    }
  }

  Future<void> _saveNotificationsToStorage() async {
    try {
      final userId = _currentUserId;

      // If no user is logged in, don't save notifications
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId'; // User-specific key
      final notificationsJson = _notifications
          .map((notification) => json.encode(notification.toJson()))
          .toList();

      await prefs.setStringList(key, notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Add a method to handle user login/logout
  Future<void> handleUserChanged(String? userId) async {
    // If the user ID is the same, do nothing
    if (_currentUserId == userId) return;

    // Update the current user ID
    _currentUserId = userId;

    // Clear current notifications
    _notifications = [];

    // If a user is logged in, load their notifications
    if (userId != null) {
      await loadSavedNotifications();
    } else {
      // If no user is logged in, just update the streams with empty lists
      _notificationsStreamController.add(_notifications);
      _unreadCountStreamController.add(0);
    }
  }

  // Method to handle FCM token refresh
  void setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((String token) async {
      print('FCM Token refreshed: $token');

      // Save the new token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // Send token to your backend
      await _sendTokenToServer(token);
    });
  }

  // Dispose method to clean up resources
  void dispose() {
    _notificationsStreamController.close();
    _unreadCountStreamController.close();
  }
}