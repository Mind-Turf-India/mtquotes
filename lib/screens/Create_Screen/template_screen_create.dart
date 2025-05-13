import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/screens/Templates/components/recent/recent_service.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import 'package:mtquotes/screens/User_Home/components/Categories/category_screen.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import '../Templates/components/festivals/festival_card.dart';
import '../Templates/components/festivals/festival_handler.dart';
import '../Templates/components/festivals/festival_post.dart';
import '../Templates/components/festivals/festival_service.dart';
import '../Templates/components/template/quote_template.dart';
import '../Templates/components/template/template_service.dart';
import '../User_Home/components/tapp_effect.dart';
import '../User_Home/components/templates_list.dart';
import 'components/image_picker_edit_screen.dart';
import 'edit_screen_create.dart';
import '../User_Home/components/Search/search_service.dart';

class TemplatePage extends StatefulWidget {
  @override
  _TemplatePageState createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {

  final QuoteTemplate defaultTemplate = QuoteTemplate(
    id: 'default_template_id',
    imageUrl: '', // Empty string for the image URL
    title: 'Default Template',
    category: 'General',
    isPaid: false,
    createdAt: DateTime.now(),
    // Optional fields can remain null
  );
  int selectedTab = 0;
  List<String> tabs = [];
  final TextEditingController _searchController = TextEditingController();
  File? _image;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  final TemplateService _templateService = TemplateService();
  bool _loadingFestivals = false;
  List<FestivalPost> _festivalPosts = [];
  final FestivalService _festivalService = FestivalService();
  final SearchService _searchService = SearchService();

  bool _isSearching = false;
  List<QuoteTemplate> _searchResults = [];

  @override
  void initState() {
    super.initState();
    initSpeech();
    _fetchFestivalPosts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    } else {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.speechRecognitionNotAvailable)),
      );
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _searchController.text = result.recognizedWords;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch(query);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final searchResults = await _searchService.searchAcrossCollections(query);

      print('Raw search results count: ${searchResults.length}');
      for (var i = 0; i < searchResults.length; i++) {
        var result = searchResults[i];
        print(
            'Result #${i + 1} - ID: ${result.id}, Title: ${result.title}, ImageURL: ${result.imageUrl}');
      }

      Map<String, QuoteTemplate> uniqueTemplatesMap = {};

      for (var result in searchResults) {
        if (result.imageUrl == null || result.imageUrl.trim().isEmpty) {
          print('Skipping result with ID: ${result.id} due to empty imageUrl');
          continue;
        }

        QuoteTemplate template = QuoteTemplate(
          id: result.id,
          title: result.title,
          imageUrl: result.imageUrl,
          category: result.type,
          avgRating: 0,
          isPaid: result.isPaid,
          createdAt: DateTime.now(),
        );

        uniqueTemplatesMap[result.id] = template;
      }

      List<QuoteTemplate> templates = uniqueTemplatesMap.values.toList();

      setState(() {
        _searchResults = templates;
        _isSearching = false;
      });

      print('Found ${templates.length} valid, unique search results');
    } catch (e) {
      print('Error in search: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _fetchFestivalPosts() async {
    setState(() {
      _loadingFestivals = true;
    });

    try {
      final festivals = await _festivalService.fetchRecentFestivalPosts();

      if (mounted) {
        setState(() {
          _festivalPosts = [];
          for (var festival in festivals) {
            _festivalPosts.addAll(FestivalPost.multipleFromFestival(festival));
          }

          for (var post in _festivalPosts) {
            print("Post: ${post.name}, Image URL: ${post.imageUrl}");
          }

          _loadingFestivals = false;
        });
      }
    } catch (e) {
      print("Error loading festival posts: $e");
      if (mounted) {
        setState(() {
          _loadingFestivals = false;
        });
      }
    }
  }

  void _handleFestivalPostSelection(FestivalPost festival) {
    FestivalHandler.handleFestivalSelection(
      context,
      festival,
      (selectedFestival) async {
        try {
          QuoteTemplate template = QuoteTemplate(
            id: selectedFestival.id,
            title: selectedFestival.name,
            imageUrl: selectedFestival.imageUrl,
            category: 'festival',
            avgRating: 0,
            isPaid: selectedFestival.isPaid,
            createdAt: DateTime.now(),
          );

          await RecentTemplateService.addRecentTemplate(template);

          _showImagePicker(context,template);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding to recent templates: $e')),
          );
        }
      },
    );
  }

  void _handleTemplateSelection(QuoteTemplate template) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      bool isSubscribed = await _templateService.isUserSubscribed();

      await RecentTemplateService.addRecentTemplate(template);

      Navigator.pop(context);

      if (!template.isPaid || isSubscribed) {
        TemplateHandler.showTemplateConfirmationDialog(
          context,
          template,
          isSubscribed,
        );
      } else {
        SubscriptionPopup.show(context);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking subscription: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      Navigator.pop(context);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // New methods for shimmer effects
  Widget _buildImageShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _buildCategoryShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFestivalShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(right: 12),
            child: Container(
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsShimmer(bool isDarkMode) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6, // Show 6 shimmer placeholders
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor:
                    isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme mode from provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get colors based on current theme
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final surfaceColor = AppColors.getSurfaceColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);
    final iconColor = AppColors.getIconColor(isDarkMode);

    // Initialize tabs with localized strings
    tabs = [context.loc.category, context.loc.gallery];

    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.template,
          style: TextStyle(color: textColor, fontSize: fontSize + 4),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style:
                    GoogleFonts.poppins(color: textColor, fontSize: fontSize),
                decoration: InputDecoration(
                  hintText: context.loc.searchquotes,
                  hintStyle: GoogleFonts.poppins(
                    color: secondaryTextColor,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/search_button.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: secondaryTextColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _isSearching = false;
                            });
                          },
                        ),
                      IconButton(
                        icon: _isListening
                            ? SvgPicture.asset(
                                'assets/icons/microphone open.svg',
                                width: 20,
                                height: 34,
                                colorFilter: ColorFilter.mode(
                                  AppColors.primaryBlue,
                                  BlendMode.srcIn,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/microphone close.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  isDarkMode
                                      ? Colors.grey[400]!
                                      : Colors.grey[600]!,
                                  BlendMode.srcIn,
                                ),
                              ),
                        onPressed: _toggleListening,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Show search results or tabs based on search state
            if (_isSearching)
              Expanded(
                child: _buildSearchResultsShimmer(isDarkMode),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: _buildSearchResultsSection(
                    fontSize, textColor, surfaceColor, isDarkMode),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(tabs.length, (index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                tabs[index],
                                style: TextStyle(
                                  color: selectedTab == index
                                      ? Colors.white
                                      : AppColors.primaryBlue,
                                ),
                              ),
                              selected: selectedTab == index,
                              selectedColor: AppColors.primaryBlue,
                              backgroundColor: surfaceColor,
                              side: BorderSide(color: AppColors.primaryBlue),
                              showCheckmark: false,
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedTab = index;
                                });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildTabContent(selectedTab, textColor,
                            surfaceColor, isDarkMode, fontSize),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context, QuoteTemplate template) {
    // Verify the template has a valid URL before proceeding
    if (template.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template image URL is empty or invalid'))
      );
      return;
    }

    print("Navigating to ImagePickerScreen with URL: ${template.imageUrl}");

    // Navigate to ImagePickerScreen with the selected template
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePickerScreen(
          templateImageUrl: template.imageUrl,
        ),
      ),
    ).then((value) {
      // Handle any value returned from the ImagePickerScreen if needed
      if (value != null) {
        print("Returned from ImagePickerScreen with value: $value");
      }
    }).catchError((error) {
      // Log any errors that might occur during navigation
      print("Error navigating to ImagePickerScreen: $error");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening image editor: $error'))
      );
    });
  }

  Widget _buildSearchResultsSection(
      double fontSize, Color textColor, Color surfaceColor, bool isDarkMode) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results (${_searchResults.length})',
            style: GoogleFonts.poppins(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final template = _searchResults[index];

              if (template.imageUrl.isEmpty) {
                return SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () => _handleTemplateSelection(template),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode ? Colors.black26 : Colors.grey.shade300,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Using CachedNetworkImage for better performance and loading indicators
                        CachedNetworkImage(
                          imageUrl: template.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildImageShimmer(isDarkMode),
                          errorWidget: (context, url, error) {
                            print(
                                'Error loading image for template ${template.id}: $error');
                            return Container(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                        // PRO badge
                        if (template.isPaid)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/premium_1659060.svg',
                                width: 24,
                                height: 24,
                                color: Colors.amber,
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
        ],
      ),
    );
  }

  Widget _buildTabContent(int index, Color textColor, Color surfaceColor,
      bool isDarkMode, double fontSize) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Tab
          if (index == 0) ...[
            SizedBox(height: 10),
            //  static category section
            Text(context.loc.categories,
                style: GoogleFonts.poppins(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDarkMode),
                )),
            SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  categoryCard('assets/icons/motivation.svg',
                      context.loc.motivational, Colors.green, isDarkMode),
                  categoryCard('assets/icons/love.svg', context.loc.love,
                      Colors.red, isDarkMode),
                  categoryCard('assets/icons/funny.svg', context.loc.funny,
                      Colors.orange, isDarkMode),
                  categoryCard(
                      'assets/icons/friendship.svg',
                      context.loc.friendship,
                      const Color(0xFF9E4282),
                      isDarkMode),
                  categoryCard('assets/icons/sad.svg', context.loc.sad,
                      const Color(0xFFAADA0D), isDarkMode),
                  categoryCard(
                      'assets/icons/patriotic.svg',
                      context.loc.patriotic,
                      const Color(0xFF000088),
                      isDarkMode
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _isSearching
                ? _buildSearchResultsShimmer(isDarkMode)
                : _searchResults.isNotEmpty
                    ? _buildSearchResultsSection(
                        fontSize, textColor, surfaceColor, isDarkMode)
                    : (_searchController.text.isNotEmpty)
                        ? Center(
                            child: Text(
                              'No results found',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize,
                                color: textColor,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.loc.newtemplate,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TemplatesListScreen(
                                            title: context.loc.newtemplate,
                                            listType: TemplateListType.festival,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      context.loc.viewall,
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSize - 2,
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                height: 150,
                                child: _loadingFestivals
                                    ? _buildFestivalShimmer(isDarkMode)
                                    : _festivalPosts.isEmpty
                                        ? Center(
                                            child: Text(
                                              "No festival posts available",
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSize - 2,
                                                color: textColor,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _festivalPosts.length,
                                            itemBuilder: (context, index) {
                                              return FestivalCard(
                                                festival: _festivalPosts[index],
                                                fontSize: fontSize,
                                                onTap: () =>
                                                    _handleFestivalPostSelection(
                                                        _festivalPosts[index]),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
            SizedBox(height: 20),
          ],

          // Gallery Tab
          if (index == 1) ...[
            SizedBox(
              width: double.infinity,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _showImagePicker(context, defaultTemplate);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.loc.selectImageFromGallery,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_image != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Image.file(
                  _image!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget categoryCard(
      String svgAssetPath, String title, Color color, bool isDarkMode) {
    return TapEffectWidget(
      scaleEffect: 0.85, // Slightly more pronounced effect
      opacityEffect: 0.99,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryName: title,
              categoryColor: color,
              categorySvgPath: svgAssetPath,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgAssetPath,
                  width: 40,
                  height: 40,
                  color: color,
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                Text(
                  context.loc.quotes,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget quoteCard(
    String text, double fontSize, Color textColor, Color backgroundColor) {
  return Container(
    width: 100,
    margin: EdgeInsets.only(right: 10),
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: backgroundColor == Colors.white
              ? Colors.grey.shade300
              : Colors.black26,
          blurRadius: 5,
        ),
      ],
    ),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: fontSize - 2,
          color: textColor,
        ),
      ),
    ),
  );
}
