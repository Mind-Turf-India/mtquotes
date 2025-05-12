import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Holiday {
  final String name;
  final String description;
  final DateTime date;
  final String type;

  Holiday({
    required this.name,
    required this.description,
    required this.date,
    required this.type,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    print('Holiday JSON data: $json');

    DateTime parseDate() {
      if (json['date'] == null) return DateTime.now();

      if (json['date'] is String) {
        return DateTime.parse(json['date']);
      } else if (json['date'] is Map) {
        return DateTime.parse(json['date']['iso'] ?? DateTime.now().toIso8601String());
      } else if (json['date'] is Timestamp) {
        return json['date'].toDate();
      }

      return DateTime.now();
    }

    String parseType() {
      if (json['type'] == null) return '';

      if (json['type'] is List) {
        return json['type'].isNotEmpty ? json['type'][0] : '';
      } else if (json['type'] is String) {
        return json['type'];
      }

      return '';
    }

    String name = json['name'] ?? '';
    if (name.isEmpty && json['text'] != null) {
      name = json['text'];
    }
    if (name.isEmpty && json['title'] != null) {
      name = json['title'];
    }

    if (name.isEmpty) {
      name = 'Untitled Holiday';
    }

    return Holiday(
      name: name,
      description: json['description'] ?? '',
      date: parseDate(),
      type: parseType(),
    );
  }
}

class HolidayService {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _useTestData = false;


  final String _apiKey =
      "sus8gIvZCBFdPdah2O24JGSXSpU2fUWc";

  Future<List<Holiday>> fetchHolidays({String country = 'IN', int? year}) async {
    try {
      year ??= DateTime.now().year;

      print('Starting API request to Calendarific for $country, $year');

      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));

      final apiKey = "sus8gIvZCBFdPdah2O24JGSXSpU2fUWc";

      final url = 'https://calendarific.com/api/v2/holidays';
      final params = {
        'api_key': apiKey,
        'country': country,
        'year': year,
      };
      print('Making request to: $url');
      print('With parameters: $params');

      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response headers: ${response.headers}');

      final responsePreview = response.data.toString().length > 500
          ? '${response.data.toString().substring(0, 500)}...'
          : response.data.toString();
      print('API Response data preview: $responsePreview');

      if (response.statusCode == 200) {
        if (response.data['response'] == null ||
            response.data['response']['holidays'] == null) {
          print('Invalid API response structure: ${response.data}');
          throw Exception('Invalid API response structure');
        }

        List<dynamic> holidaysJson = response.data['response']['holidays'];
        print('Successfully found ${holidaysJson.length} holidays from API');

        return holidaysJson.map((json) => Holiday.fromJson(json)).toList();
      } else {
        print('Failed API response: ${response.statusCode}, ${response.data}');
        throw Exception('Failed to fetch holidays: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching holidays from API: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('DioException response: ${e.response?.data}');
        print('DioException stacktrace: ${e.stackTrace}');
      }

      print('Attempting to fetch from Firestore instead...');
      return getHolidaysFromFirestore();
    }
  }

  Future<List<Holiday>> getHolidaysFromFirestore() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('holidays').orderBy('date').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Holiday(
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          date: data['date'] != null
              ? (data['date'] is Timestamp
                  ? data['date'].toDate()
                  : DateTime.parse(data['date']))
              : DateTime.now(),
          type: data['type'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting holidays from Firestore: $e');
      return [];
    }
  }

  Map<DateTime, List<Holiday>> groupHolidaysByDate(List<Holiday> holidays) {
    print('Grouping ${holidays.length} holidays by date');

    final Map<DateTime, List<Holiday>> grouped = {};

    for (var holiday in holidays) {
      final DateTime dateKey = DateTime(
          holiday.date.year,
          holiday.date.month,
          holiday.date.day
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(holiday);
      print('Added holiday "${holiday.name}" to date ${DateFormat('yyyy-MM-dd').format(dateKey)}');
    }

    print('Grouped into ${grouped.length} dates');

    return grouped;
  }
}
