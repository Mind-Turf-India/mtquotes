class Step1Data {
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final String? profileImagePath;
  final List<Education> education;

  Step1Data({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.postalCode,
    this.profileImagePath,
    required this.education,
  });
}

class Step2Data {
  final String summary;
  final List<Employment> employment;

  Step2Data({
    required this.summary,
    required this.employment,
  });
}

class ResumeData {
  final String userId;
  final String templateType;
  final PersonalInfo personalInfo;
  final List<Education> education;
  final String professionalSummary;
  final List<Employment> employmentHistory;
  final List<String> skills;
  final List<String> languages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResumeData({
    required this.userId,
    required this.templateType,
    required this.personalInfo,
    required this.education,
    required this.professionalSummary,
    required this.employmentHistory,
    required this.skills,
    required this.languages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'templateType': templateType,
      'personalInfo': personalInfo.toMap(),
      'education': education.map((e) => e.toMap()).toList(),
      'professionalSummary': professionalSummary,
      'employmentHistory': employmentHistory.map((e) => e.toMap()).toList(),
      'skills': skills,
      'languages': languages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ResumeData.fromMap(Map<String, dynamic> map) {
    return ResumeData(
      userId: map['userId'],
      templateType: map['templateType'],
      personalInfo: PersonalInfo.fromMap(map['personalInfo']),
      education: List<Education>.from(
        map['education']?.map((x) => Education.fromMap(x)) ?? [],
      ),
      professionalSummary: map['professionalSummary'] ?? '',
      employmentHistory: List<Employment>.from(
        map['employmentHistory']?.map((x) => Employment.fromMap(x)) ?? [],
      ),
      skills: List<String>.from(map['skills'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class PersonalInfo {
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final String? profileImagePath;

  PersonalInfo({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.postalCode,
    this.profileImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'profileImagePath': profileImagePath,
    };
  }

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      role: map['role'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      postalCode: map['postalCode'] ?? '',
      profileImagePath: map['profileImagePath'],
    );
  }
}

class Education {
  final String title;
  final String school;
  final String level;
  final String startDate;
  final String endDate;
  final String location;
  // final String description;

  Education({
    required this.title,
    required this.school,
    required this.level,
    required this.startDate,
    required this.endDate,
    required this.location,
    // required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'school': school,
      'level': level,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      // 'description': description,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      title: map['title'] ?? '',
      school: map['school'] ?? '',
      level: map['level'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      location: map['location'] ?? '',
      // description: map['description'] ?? '',
    );
  }
}

class Employment {
  final String jobTitle;
  final String employer;
  final String startDate;
  final String endDate;
  final String location;
  final String description;

  Employment({
    required this.jobTitle,
    required this.employer,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobTitle': jobTitle,
      'employer': employer,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'description': description,
    };
  }

  factory Employment.fromMap(Map<String, dynamic> map) {
    return Employment(
      jobTitle: map['jobTitle'] ?? '',
      employer: map['employer'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

// Extension for string utilities
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}