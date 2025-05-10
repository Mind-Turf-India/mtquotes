import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../Templates/components/template/quote_template.dart';
import '../../../Templates/unified_model.dart';

class FeedManagerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _currentUserName = "User";
  String _currentUserProfileUrl = "";

  // Maximum number of initial items to fetch per source
  final int _initialItemsPerSource = 50;

  // Number of posts before showing a horizontal section
  final int _postsBeforeSection = 2;

  // Track pagination cursors for each content type
  DocumentSnapshot? _lastTrendingDoc;
  DocumentSnapshot? _lastTotdDoc;
  int _totdOffset = 0;

  // Track whether we've reached the end of each content type
  bool _trendingHasMore = true;
  bool _totdHasMore = true;

  // Lists to store fetched content
  List<UnifiedPost> _trendingPosts = [];
  List<UnifiedPost> _totdPosts = [];
  List<UnifiedPost> _qotdPosts = [];

  // Get the current date in the format used by QOTD collection
  String _getCurrentDateString() {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // Get current time of day (morning, afternoon, evening)
  String _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }


  void setCurrentUserInfo(String userName, String profileUrl) {
    _currentUserName = userName;
    _currentUserProfileUrl = profileUrl;
  }

  // Fetch Quote of the Day
  Future<List<UnifiedPost>> fetchQOTD() async {
    try {
      // If we already fetched QOTD, return it
      if (_qotdPosts.isNotEmpty) {
        return _qotdPosts;
      }

      String formattedDate = _getCurrentDateString();
      DocumentSnapshot snapshot = await _firestore
          .collection('qotd')
          .doc(formattedDate)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        _qotdPosts = [UnifiedPost.fromQOTD(
          snapshot.id,
          snapshot.data() as Map<String, dynamic>,
          userName: _currentUserName,
          userProfileUrl: _currentUserProfileUrl,
        )];
        return _qotdPosts;
      }

      // If today's QOTD doesn't exist, try to get yesterday's
      DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
      String yesterdayFormatted = DateFormat('dd-MM-yyyy').format(yesterday);

      snapshot = await _firestore
          .collection('qotd')
          .doc(yesterdayFormatted)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        _qotdPosts = [UnifiedPost.fromQOTD(
          snapshot.id,
          snapshot.data() as Map<String, dynamic>,
          userName: _currentUserName,
          userProfileUrl: _currentUserProfileUrl,
        )];
        return _qotdPosts;
      }

      return [];
    } catch (e) {
      print('Error fetching QOTD: $e');
      return [];
    }
  }

  // Fetch initial trending templates
  Future<List<UnifiedPost>> fetchInitialTrendingTemplates() async {
    try {
      // Clear any existing posts and pagination cursors
      _trendingPosts = [];
      _lastTrendingDoc = null;
      _trendingHasMore = true;

      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .orderBy('rating', descending: true)
          .limit(_initialItemsPerSource)
          .get();

      if (snapshot.docs.isEmpty) {
        _trendingHasMore = false;
        return [];
      }

      _lastTrendingDoc = snapshot.docs.last;

      List<UnifiedPost> posts = snapshot.docs.map((doc) =>
          UnifiedPost.fromTrending(
            doc,
            userName: _currentUserName,
            userProfileUrl: _currentUserProfileUrl,
          )
      ).toList();

      _trendingPosts = posts;
      return posts;
    } catch (e) {
      print('Error fetching initial trending templates: $e');
      return [];
    }
  }

  // Fetch more trending templates for pagination
  // Update in fetchMoreTrendingTemplates
  Future<List<UnifiedPost>> fetchMoreTrendingTemplates() async {
    if (!_trendingHasMore || _lastTrendingDoc == null) {
      return [];
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('templates')
          .orderBy('rating', descending: true)
          .startAfterDocument(_lastTrendingDoc!)
          .limit(_initialItemsPerSource)
          .get();

      if (snapshot.docs.isEmpty) {
        _trendingHasMore = false;
        return [];
      }

      _lastTrendingDoc = snapshot.docs.last;

      List<UnifiedPost> newPosts = snapshot.docs.map((doc) =>
          UnifiedPost.fromTrending(
            doc,
            userName: _currentUserName,
            userProfileUrl: _currentUserProfileUrl,
          )
      ).toList();

      _trendingPosts.addAll(newPosts);
      return newPosts;
    } catch (e) {
      print('Error fetching more trending templates: $e');
      return [];
    }
  }

  // Fetch initial Time of Day posts
  Future<List<UnifiedPost>> fetchInitialTOTDPosts() async {
    try {
      // Clear any existing posts and reset pagination
      _totdPosts = [];
      _totdOffset = 0;
      _totdHasMore = true;

      String timeOfDay = _getCurrentTimeOfDay();
      DocumentSnapshot snapshot = await _firestore
          .collection('totd')
          .doc(timeOfDay)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        _totdHasMore = false;
        return [];
      }

      List<UnifiedPost> posts = [];
      final data = snapshot.data() as Map<String, dynamic>;

      // Convert data to a list for easier pagination
      List<MapEntry<String, dynamic>> postEntries = data.entries
          .where((entry) => entry.key.startsWith('post'))
          .toList();

      // Apply initial offset limit
      int endIndex = _totdOffset + _initialItemsPerSource;
      if (endIndex > postEntries.length) {
        endIndex = postEntries.length;
        if (endIndex == postEntries.length) {
          _totdHasMore = false;
        }
      }

      // Convert entries to posts
      for (int i = _totdOffset; i < endIndex; i++) {
        var entry = postEntries[i];
        if (entry.value is Map<String, dynamic>) {
          posts.add(UnifiedPost.fromTOTD(
            timeOfDay,
            entry.key,
            entry.value as Map<String, dynamic>,
            userName: _currentUserName,
            userProfileUrl: _currentUserProfileUrl,
          ));
        }
      }

      // Update the offset for next pagination
      _totdOffset = endIndex;

      _totdPosts = posts;
      return posts;
    } catch (e) {
      print('Error fetching initial TOTD posts: $e');
      return [];
    }
  }

  // Fetch more TOTD posts for pagination
  // In FeedManagerService class, update the fetchMoreTOTDPosts method:
  Future<List<UnifiedPost>> fetchMoreTOTDPosts() async {
    if (!_totdHasMore) {
      return [];
    }

    try {
      String timeOfDay = _getCurrentTimeOfDay();
      DocumentSnapshot snapshot = await _firestore
          .collection('totd')
          .doc(timeOfDay)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        _totdHasMore = false;
        return [];
      }

      List<UnifiedPost> newPosts = [];
      final data = snapshot.data() as Map<String, dynamic>;

      // Convert data to a list for easier pagination
      List<MapEntry<String, dynamic>> postEntries = data.entries
          .where((entry) => entry.key.startsWith('post'))
          .toList();

      // Apply pagination
      int endIndex = _totdOffset + _initialItemsPerSource;
      if (endIndex > postEntries.length) {
        endIndex = postEntries.length;
        if (endIndex == postEntries.length) {
          _totdHasMore = false;
        }
      }

      // If we've already reached the end
      if (_totdOffset >= postEntries.length) {
        _totdHasMore = false;
        return [];
      }

      // Convert entries to posts - add userName and userProfileUrl here
      for (int i = _totdOffset; i < endIndex; i++) {
        var entry = postEntries[i];
        if (entry.value is Map<String, dynamic>) {
          newPosts.add(UnifiedPost.fromTOTD(
            timeOfDay,
            entry.key,
            entry.value as Map<String, dynamic>,
            userName: _currentUserName,
            userProfileUrl: _currentUserProfileUrl,
          ));
        }
      }

      // Update the offset for next pagination
      _totdOffset = endIndex;

      _totdPosts.addAll(newPosts);
      return newPosts;
    } catch (e) {
      print('Error fetching more TOTD posts: $e');
      return [];
    }
  }

  // Generate a combined initial feed
  Future<List<dynamic>> generateInitialFeed() async {
    try {
      // Fetch content from all sources
      final qotdPosts = await fetchQOTD();
      final trendingPosts = await fetchInitialTrendingTemplates();
      final totdPosts = await fetchInitialTOTDPosts();

      // Start with QOTD at the top if available
      List<dynamic> combinedFeed = [];

      if (qotdPosts.isNotEmpty) {
        combinedFeed.add(qotdPosts.first);
      }

      // Create a copy of trending and TOTD posts to work with
      List<UnifiedPost> allPosts = [...trendingPosts, ...totdPosts];

      // Sort by rating as the primary factor
      allPosts.sort((a, b) => b.rating.compareTo(a.rating));

      // Add posts to feed, interspersing section markers
      int totalPosts = 0;
      int postCount = 0;

      for (int i = 0; i < allPosts.length; i++) {
        combinedFeed.add(allPosts[i]);
        postCount++;
        totalPosts++;

        // After every _postsBeforeSection posts, add section markers
        if (postCount == _postsBeforeSection && totalPosts < allPosts.length) {
          postCount = 0; // Reset post counter

          // Determine which section to show based on the total posts seen so far
          int sectionType = (totalPosts ~/ _postsBeforeSection) % 3;

          if (sectionType == 0) {
            combinedFeed.add('trending_section');
          } else if (sectionType == 1) {
            combinedFeed.add('new_templates_section');
          } else {
            combinedFeed.add('for_you_section');
          }
        }
      }

      return combinedFeed;
    } catch (e) {
      print('Error generating initial feed: $e');
      return [];
    }
  }

  // Fetch more content for infinite scrolling
  Future<List<dynamic>> fetchMoreContent() async {
    try {
      // Determine which content source to fetch more from
      List<UnifiedPost> newPosts = [];

      // Alternate between trending and TOTD based on which one has fewer items
      if (_trendingPosts.length <= _totdPosts.length && _trendingHasMore) {
        newPosts = await fetchMoreTrendingTemplates();
      } else if (_totdHasMore) {
        newPosts = await fetchMoreTOTDPosts();
      }

      // If both sources are exhausted, try refreshing them both
      if (newPosts.isEmpty && !_trendingHasMore && !_totdHasMore) {
        // Reset pagination and try again
        _lastTrendingDoc = null;
        _totdOffset = 0;
        _trendingHasMore = true;
        _totdHasMore = true;

        List<UnifiedPost> moreTrending = await fetchMoreTrendingTemplates();
        List<UnifiedPost> moreTOTD = await fetchMoreTOTDPosts();

        newPosts = [...moreTrending, ...moreTOTD];
      }

      if (newPosts.isEmpty) {
        return [];
      }

      // Sort by rating
      newPosts.sort((a, b) => b.rating.compareTo(a.rating));

      // Add posts to feed with section markers
      List<dynamic> moreContent = [];
      int postCount = 0;
      int totalPosts = 0;

      for (int i = 0; i < newPosts.length; i++) {
        moreContent.add(newPosts[i]);
        postCount++;
        totalPosts++;

        // After every _postsBeforeSection posts, add section markers
        if (postCount == _postsBeforeSection && i < newPosts.length - 1) {
          postCount = 0; // Reset post counter

          // Determine which section to show in a rotating fashion
          int sectionType = (totalPosts ~/ _postsBeforeSection) % 3;

          if (sectionType == 0) {
            moreContent.add('trending_section');
          } else if (sectionType == 1) {
            moreContent.add('new_templates_section');
          } else {
            moreContent.add('for_you_section');
          }
        }
      }

      return moreContent;
    } catch (e) {
      print('Error fetching more content: $e');
      return [];
    }
  }

  // Method to convert feedItem to QuoteTemplate if needed
  QuoteTemplate? convertToQuoteTemplate(dynamic feedItem) {
    if (feedItem is UnifiedPost) {
      return feedItem.toQuoteTemplate();
    }
    return null;
  }
}