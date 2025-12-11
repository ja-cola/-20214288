import 'dart:convert';

import 'package:flutter/material.dart';
import '../detail/detail_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const QuestionPage({super.key, required this.question});

  @override
  State<StatefulWidget> createState() {
    return _QuestionPage();
  }
}

class _QuestionPage extends State<QuestionPage> {
  int? selectedOption;

  Future<void> _saveHistory(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('history') ?? [];
    final now = DateTime.now().toString().substring(0, 16);

    final record = {
      "title": widget.question["title"],
      "question": widget.question["question"],
      "answer": answer,
      "time": now,
    };

    list.add(jsonEncode(record));
    await prefs.setStringList('history', list);
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.question["title"] ?? "";
    final String qText = widget.question["question"] ?? "";
    final List selects = widget.question["selects"] ?? [];
    final List answers = widget.question["answer"] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 1.0,
              color: Colors.deepPurple,
              backgroundColor: Colors.deepPurple.shade50,
            ),
            const SizedBox(height: 20),
            Text(
              qText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: selects.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedOption == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        selects[index].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color:
                        isSelected ? Colors.deepPurple : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          selectedOption = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: selectedOption == null
                    ? null
                    : () async {
                  final selectedIndex = selectedOption!;
                  final answerText = answers[selectedIndex].toString();

                  await FirebaseAnalytics.instance.logEvent(
                    name: "personal_select",
                    parameters: {
                      "test_name": title,
                      "select_index": selectedIndex,
                    },
                  );

                  await _saveHistory(answerText);

                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        answer: answerText,
                        question: qText,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                child: const Text(
                  '결과 보기',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
