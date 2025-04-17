import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_resume_template/flutter_resume_template.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({Key? key}) : super(key: key);

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TemplateTheme theme = TemplateTheme.classic; // Default to classic to avoid modern theme issues
  bool _isLoading = true;
  late TemplateData _templateData;

  List<TemplateTheme> themeList = [
    TemplateTheme.classic,
    TemplateTheme.technical,
    TemplateTheme.modern, // Move modern to the end since it has issues
  ];

  @override
  void initState() {
    super.initState();
    _loadResumeData();
  }

  // Get the current user's document ID (email with _ replacing .)
  String get _userDocId {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.email!.replaceAll('.', '_');
    }
    return '';
  }

  // Load resume data from Firestore
  Future<void> _loadResumeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userDocId)
          .get();

      // Initialize with properly filled dummy data
      _templateData = _createSampleTemplateData();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;

        // Basic profile information from user document
        final name = userData['name'] ?? 'Your Name';
        final email = userData['email'] ?? 'email@example.com';
        final phone = userData['mobile'] ?? '123-456-7890';
        final location = userData['location'] ?? 'Your Location';
        final bio = userData['bio'] ?? 'Write something about yourself...';

        // Create resume data using available user info
        _templateData = TemplateData(
          fullName: name,
          email: email,
          phoneNumber: phone,
          address: location,
          currentPosition: 'Your Position',
          bio: bio,
          // Always provide at least one item in these lists
          experience: [
            ExperienceData(
              experienceTitle: 'Your Job Title',
              experienceLocation: 'Company Name',
              experiencePeriod: '2020 - Present',
              experiencePlace: 'Location',
              experienceDescription: 'Describe your responsibilities and achievements...',
            )
          ],
          educationDetails: [
            Education(
              'Your Degree',
              'University/Institution Name',
            )
          ],
          languages: [
            Language('English', 5),
          ],
          hobbies: ['Reading', 'Writing', 'Coding'],
        );

        // If there's existing resume data in Firestore, use that instead
        if (userData.containsKey('resumeData')) {
          final resumeData = userData['resumeData'] as Map<String, dynamic>;
          _templateData = _convertMapToTemplateData(resumeData);
        }

        // Load the saved theme if available
        if (userData.containsKey('resumeTheme')) {
          final themeIndex = userData['resumeTheme'] as int;
          if (themeIndex >= 0 && themeIndex < themeList.length) {
            theme = themeList[themeIndex];
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading resume data: $e')),
      );
      // Use sample template data in case of error
      _templateData = _createSampleTemplateData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create sample template data with dummy values
  TemplateData _createSampleTemplateData() {
    return TemplateData(
      fullName: 'Your Name',
      currentPosition: 'Your Position',
      email: 'email@example.com',
      phoneNumber: '123-456-7890',
      address: 'Your Location',
      bio: 'Write something about yourself...',
      experience: [
        ExperienceData(
          experienceTitle: 'Your Job Title',
          experienceLocation: 'Company Name',
          experiencePeriod: '2020 - Present',
          experiencePlace: 'Location',
          experienceDescription: 'Describe your responsibilities and achievements...',
        )
      ],
      educationDetails: [
        Education(
          'Your Degree',
          'University/Institution Name',
        )
      ],
      languages: [
        Language('English', 5),
      ],
      hobbies: ['Reading', 'Writing', 'Coding'],
    );
  }

  // Create empty template data
  TemplateData _createEmptyTemplateData() {
    return TemplateData(
      fullName: '',
      currentPosition: '',
      email: '',
      phoneNumber: '',
      address: '',
      bio: '',
      // Provide at least one element in each list to avoid range errors
      experience: [
        ExperienceData(
          experienceTitle: '',
          experienceLocation: '',
          experiencePeriod: '',
          experiencePlace: '',
          experienceDescription: '',
        )
      ],
      educationDetails: [
        Education('', '')
      ],
      languages: [
        Language('', 1)
      ],
      hobbies: [''],
    );
  }

  // Convert Firestore Map to TemplateData
  TemplateData _convertMapToTemplateData(Map<String, dynamic> map) {
    // Parse experience data
    List<ExperienceData> experiences = [];
    if (map.containsKey('experience') && map['experience'] is List) {
      for (var item in map['experience']) {
        experiences.add(
          ExperienceData(
            experienceTitle: item['title'] ?? '',
            experienceLocation: item['company'] ?? '',
            experiencePeriod: item['duration'] ?? '',
            experiencePlace: item['company'] ?? '', // Use company as place if not specified
            experienceDescription: item['description'] ?? '',
          ),
        );
      }
    }

    // If no experiences, add a placeholder
    if (experiences.isEmpty) {
      experiences.add(
          ExperienceData(
            experienceTitle: 'Your Job Title',
            experienceLocation: 'Company Name',
            experiencePeriod: '2020 - Present',
            experiencePlace: 'Location',
            experienceDescription: 'Describe your responsibilities and achievements...',
          )
      );
    }

    // Parse education data
    List<Education> education = [];
    if (map.containsKey('education') && map['education'] is List) {
      for (var item in map['education']) {
        education.add(
          Education(
            item['degree'] ?? '',
            item['institution'] ?? '',
          ),
        );
      }
    }

    // If no education, add a placeholder
    if (education.isEmpty) {
      education.add(Education('Your Degree', 'University/Institution Name'));
    }

    // Parse language data
    List<Language> languages = [];
    if (map.containsKey('language') && map['language'] is List) {
      for (var item in map['language']) {
        languages.add(
          Language(
            item['title'] ?? '',
            _parseLanguageLevel(item['level'] ?? ''),
          ),
        );
      }
    }

    // If no languages, add a placeholder
    if (languages.isEmpty) {
      languages.add(Language('English', 5));
    }

    // Parse hobbies
    List<String> hobbies = [];
    if (map.containsKey('hobbies') && map['hobbies'] is List) {
      hobbies = List<String>.from(map['hobbies']);
    }

    // If no hobbies, add placeholders
    if (hobbies.isEmpty) {
      hobbies = ['Reading', 'Writing', 'Coding'];
    }

    return TemplateData(
      fullName: map['name'] ?? 'Your Name',
      currentPosition: map['designation'] ?? 'Your Position',
      email: map['email'] ?? 'email@example.com',
      phoneNumber: map['mobile'] ?? '123-456-7890',
      address: map['location'] ?? 'Your Location',
      bio: map['about'] ?? 'Write something about yourself...',
      experience: experiences,
      educationDetails: education,
      languages: languages,
      hobbies: hobbies,
    );
  }

  // Parse language level (convert string to int)
  int _parseLanguageLevel(String level) {
    // Try to parse the level as a number
    try {
      return int.parse(level);
    } catch (e) {
      // If level is a string like "Fluent", "Intermediate", etc.
      // Convert to a numeric scale (1-5)
      switch (level.toLowerCase()) {
        case 'native':
        case 'fluent':
          return 5;
        case 'advanced':
          return 4;
        case 'intermediate':
          return 3;
        case 'basic':
          return 2;
        case 'beginner':
          return 1;
        default:
          return 3; // Default to middle level
      }
    }
  }

  // Convert TemplateData to a Map for Firestore
  Map<String, dynamic> _convertTemplateDataToMap(TemplateData data) {
    return {
      'name': data.fullName,
      'email': data.email,
      'mobile': data.phoneNumber,
      'location': data.address,
      'designation': data.currentPosition,
      'about': data.bio,
      'experience': data.experience?.map((e) => {
        'title': e.experienceTitle,
        'company': e.experienceLocation,
        'duration': e.experiencePeriod,
        'description': e.experienceDescription,
      }).toList() ?? [],
      'education': data.educationDetails?.map((e) => {
        'institution': e.schoolName,
        'degree': e.schoolLevel,
      }).toList() ?? [],
      'language': data.languages?.map((e) => {
        'title': e.language,
        'level': e.level.toString(),
      }).toList() ?? [],
      'hobbies': data.hobbies ?? [],
    };
  }

  // Save resume data to Firestore
  Future<GlobalKey<State<StatefulWidget>>> _saveResumeData(GlobalKey<State<StatefulWidget>> key) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert TemplateData to Map
      final resumeMap = _convertTemplateDataToMap(_templateData);

      // Get the current theme index
      int themeIndex = themeList.indexOf(theme);

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userDocId)
          .update({
        'resumeData': resumeMap,
        'resumeTheme': themeIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving resume data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    return key;
  }

  // Change the resume template theme
  void _changeTheme() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Resume Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: themeList.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_getThemeName(themeList[index])),
                selected: theme == themeList[index],
                onTap: () {
                  setState(() {
                    theme = themeList[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Get readable theme name
  String _getThemeName(TemplateTheme theme) {
    if (theme == TemplateTheme.classic) {
      return 'Classic';
    } else if (theme == TemplateTheme.modern) {
      return 'Modern';
    } else if (theme == TemplateTheme.technical) {
      return 'Technical';
    } else {
      return theme.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My Resume'),
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            onPressed: _changeTheme,
            tooltip: 'Change Template',
          ),
        ],
      ),
      body: FlutterResumeTemplate(
        data: _templateData,
        imageHeight: 100,
        imageWidth: 100,
        emailPlaceHolder: 'Email:',
        telPlaceHolder: 'Phone:',
        experiencePlaceHolder: 'Experience',
        educationPlaceHolder: 'Education',
        languagePlaceHolder: 'Skills',
        aboutMePlaceholder: 'About Me',
        hobbiesPlaceholder: 'Hobbies',
        // Use edit mode to ensure text fields are editable
        mode: TemplateMode.onlyEditableMode,
        showButtons: true,
        imageBoxFit: BoxFit.cover,
        enableDivider: true,
        onSaveResume: _saveResumeData,
        templateTheme: theme,
      ),
    );
  }
}