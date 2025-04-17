// These models are provided by the flutter_resume_template package
// This file is for reference only

// The main TemplateData model
class TemplateData {
  final String name;
  final String email;
  final String mobile;
  final String location;
  final String designation;
  final String about;
  final List<ExperienceItem> experience;
  final List<EducationItem> education;
  final List<LanguageItem> language;
  final List<String> hobbies;
  final String? url;
  final String? photoUrl;

  TemplateData({
    required this.name,
    required this.email,
    required this.mobile,
    required this.location,
    required this.designation,
    required this.about,
    required this.experience,
    required this.education,
    required this.language,
    required this.hobbies,
    this.url,
    this.photoUrl,
  });
}

// Experience item for work history
class ExperienceItem {
  final String title;
  final String company;
  final String duration;
  final String description;

  ExperienceItem({
    required this.title,
    required this.company,
    required this.duration,
    required this.description,
  });
}

// Education item for academic background
class EducationItem {
  final String institution;
  final String degree;
  final String duration;
  final String description;

  EducationItem({
    required this.institution,
    required this.degree,
    required this.duration,
    required this.description,
  });
}

// Language or skills item
class LanguageItem {
  final String title;
  final String level;

  LanguageItem({
    required this.title,
    required this.level,
  });
}