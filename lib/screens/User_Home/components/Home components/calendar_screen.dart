import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final HolidayService _holidayService = HolidayService();
  Map<DateTime, List<Holiday>> _groupedHolidays = {};
  List<DateTime> _sortedDates = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final holidays = await _holidayService.fetchHolidays();

      if (holidays.isEmpty) {
        setState(() {
          _errorMessage = 'No holidays found. Please check your connection and try again.';
          _isLoading = false;
        });
        return;
      }

      final grouped = _holidayService.groupHolidaysByDate(holidays);

      setState(() {
        _groupedHolidays = grouped;
        _sortedDates = grouped.keys.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load holidays: $e');
      setState(() {
        _errorMessage = 'Failed to load holidays. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHolidays,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHolidays,
              child: const Text('Try Again'),
            ),
          ],
        ),
      )
          : _sortedDates.isEmpty
          ? const Center(child: Text('No holidays found'))
          : ListView.builder(
        itemCount: _sortedDates.length,
        itemBuilder: (context, index) {
          final date = _sortedDates[index];
          final holidays = _groupedHolidays[date] ?? [];
          return _buildDateSection(date, holidays);
        },
      ),
    );
  }


  Widget _buildDateSection(DateTime date, List<Holiday> holidays) {
    final formattedDate = DateFormat('dd/MM/yyyy - EEEE').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            formattedDate,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...holidays.map((holiday) => _buildEventCard(date, holiday)).toList(),
      ],
    );
  }

  Widget _buildEventCard(DateTime date, Holiday holiday) {
    print('Building event card for holiday: ${holiday.name} on ${holiday.date}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        holiday.name.isNotEmpty ? holiday.name : 'Unnamed Holiday',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    // Icon(Icons.grid_view, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HolidaySettingsScreen extends StatefulWidget {
  const HolidaySettingsScreen({Key? key}) : super(key: key);

  @override
  _HolidaySettingsScreenState createState() => _HolidaySettingsScreenState();
}

class _HolidaySettingsScreenState extends State<HolidaySettingsScreen> {
  final HolidayService _holidayService = HolidayService();
  final TextEditingController _countryController = TextEditingController(text: 'US');
  final TextEditingController _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  bool _isLoading = false;

  Future<void> _fetchHolidays() async {
    if (_countryController.text.isEmpty || _yearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter country and year')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int year = int.parse(_yearController.text);
      await _holidayService.fetchHolidays(
        country: _countryController.text,
        year: year,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Holidays fetched successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch holidays: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country Code (e.g., US, IN)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchHolidays,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Fetch Holidays'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}