import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/text_size_provider.dart';

class TextSizeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double fontSize = context.watch<TextSizeProvider>().fontSize; // Get font size

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Text Size Adjuster", style: TextStyle(fontSize: fontSize)),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Text Size",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 5),
              Text(
                "Set up your text size using slider",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 30),
              Text(
                "Ab",
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Ab", style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Consumer<TextSizeProvider>(
                      builder: (context, textSizeProvider, child) {
                        return Slider(
                          value: textSizeProvider.fontSize,
                          min: 10,
                          max: 50,
                          divisions: 8,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.black,
                          onChanged: (value) {
                            textSizeProvider.setFontSize(value);
                          },
                        );
                      },
                    ),
                  ),
                  Text("Ab", style: TextStyle(fontSize: 30)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
