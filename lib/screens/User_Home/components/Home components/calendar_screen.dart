import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HolidayFetchScreen extends StatefulWidget {
  const HolidayFetchScreen({Key? key}) : super(key: key);

  @override
  _HolidayFetchScreenState createState() => _HolidayFetchScreenState();
}

class _HolidayFetchScreenState extends State<HolidayFetchScreen> {
  bool _isLoading = false;
  String _resultMessage = "";

  // These should be your actual values
  final String _cloudFunctionUrl = "projects/mind-turf/locations/us-central1/functions/fetchAndStoreHolidays";

  // Year and country inputs
  final TextEditingController _yearController = TextEditingController(text: "2025");
  final TextEditingController _countryController = TextEditingController(text: "IN");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fetch Holidays"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: "Year",
                hintText: "Enter year (e.g., 2025)",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: "Country Code",
                hintText: "Enter country code (e.g., IN for India)",
              ),
              maxLength: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchHolidays,
              child: _isLoading
                  ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text("Fetching..."),
                ],
              )
                  : const Text("Fetch Holidays"),
            ),
            const SizedBox(height: 24),
            if (_resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _resultMessage.contains("Error")
                        ? Colors.red
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_resultMessage),
              ),
            const SizedBox(height: 24),
            const Text(
              "Note: After fetching holidays, go back to the Calendar screen to see them.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchHolidays() async {
    try {
      setState(() {
        _isLoading = true;
        _resultMessage = "Fetching holidays...";
      });

      final year = _yearController.text.trim();
      final country = _countryController.text.trim().toUpperCase();

      if (year.isEmpty || country.isEmpty) {
        setState(() {
          _isLoading = false;
          _resultMessage = "Error: Year and country code are required.";
        });
        return;
      }

      // Call the Cloud Function
      final response = await http.get(
        Uri.parse('$_cloudFunctionUrl?year=$year&country=$country'),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _isLoading = false;
          _resultMessage = "Success: ${response.body}";
        });
      } else {
        setState(() {
          _isLoading = false;
          _resultMessage = "Error: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = "Error: ${e.toString()}";
      });
    }
  }
}