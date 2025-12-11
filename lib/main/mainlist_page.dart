import 'dart:convert';

import 'package:flutter/material.dart';
import '../sub/question_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;
  late DatabaseReference _testRef;

  String welcomeTitle = '심리테스트';
  bool bannerUse = false;
  int itemHeight = 90;

  List<Map<String, dynamic>> testList = [];
  Set<String> favoriteTitles = {};

  @override
  void initState() {
    super.initState();
    _testRef = database.ref('test');
    _initRemoteConfig();
    _loadFavorites();
  }

  Future<void> _initRemoteConfig() async {
    await remoteConfig.fetch();
    await remoteConfig.activate();
    welcomeTitle = remoteConfig.getString('welcome').isEmpty
        ? '심리테스트'
        : remoteConfig.getString('welcome');
    bannerUse = remoteConfig.getBool('banner');
    itemHeight = remoteConfig.getInt('item_height');
    if (itemHeight <= 0) itemHeight = 90;
    setState(() {});
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteTitles =
        (prefs.getStringList('favorites') ?? []).toSet();
    setState(() {});
  }

  Future<void> _toggleFavorite(String title) async {
    final prefs = await SharedPreferences.getInstance();
    if (favoriteTitles.contains(title)) {
      favoriteTitles.remove(title);
    } else {
      favoriteTitles.add(title);
    }
    await prefs.setStringList('favorites', favoriteTitles.toList());
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _loadTests() async {
    try {
      final snapshot = await _testRef.get();
      testList.clear();

      for (var element in snapshot.children) {
        final v = element.value;
        if (v != null && v is Map) {
          final data = Map<String, dynamic>.from(v);
          testList.add(data);
        }
      }

      return testList;
    } catch (e) {
      debugPrint('Failed to load data: $e');
      return [];
    }
  }

  void _openHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ResultHistoryPage(),
      ),
    );
  }

  void _addSampleTests() {
    _testRef.push().set({
      "title": "당신이 좋아하는 애완동물은?",
      "question": "무인도에 도착했는데, 상자를 열었을 때 보이는 것은?",
      "selects": ["생존 키트", "휴대폰", "텐트", "무인도에서 살아남기"],
      "answer": [
        "당신은 현실주의!",
        "당신은 동반자를 좋아하는 강아지형!",
        "당신은 공간을 공유하는 고양이형!",
        "당신은 자유로운 앵무새형!"
      ]
    });

    _testRef.push().set({
      "title": "5초 MBTI I/E 편",
      "question": "친구와 함께 간 미술관 당신이라면?",
      "selects": ["말이 많아짐", "생각이 많아짐"],
      "answer": ["당신의 성향은 E", "당신의 성향은 I"]
    });

    _testRef.push().set({
      "title": "당신은 어떤 사랑을 하고 싶나요?",
      "question": "목욕을 할 때 가장 먼저 비누칠하는 곳은?",
      "selects": ["머리", "상체", "하체"],
      "answer": [
        "당신은 자만추형이에요.",
        "당신은 소개팅형이에요.",
        "당신은 운명형이에요."
      ]
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          bannerUse ? welcomeTitle : "심리테스트 앱",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: "결과 히스토리",
            onPressed: _openHistoryPage,
            icon: const Icon(Icons.history, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadTests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("등록된 테스트가 없습니다.\n아래 + 버튼을 눌러 예시 테스트를 추가해보세요."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final title = item["title"]?.toString() ?? "제목 없음";
              final isFav = favoriteTitles.contains(title);

              return GestureDetector(
                onTap: () async {
                  await FirebaseAnalytics.instance.logEvent(
                    name: 'test_click',
                    parameters: {'test_name': title},
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuestionPage(question: item),
                    ),
                  );
                },
                child: Container(
                  height: itemHeight.toDouble(),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_alt,
                          color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.star : Icons.star_border,
                          color: Colors.yellowAccent,
                        ),
                        onPressed: () {
                          _toggleFavorite(title);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addSampleTests,
      ),
    );
  }
}

// ================= 결과 히스토리 페이지 =================

class ResultHistoryPage extends StatelessWidget {
  const ResultHistoryPage({super.key});

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('history') ?? [];
    return list
        .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 결과 기록"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text("아직 저장된 결과가 없습니다."));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, index) {
              final item = data[index];
              return ListTile(
                title: Text(item["question"] ?? ""),
                subtitle: Text(item["answer"] ?? ""),
                trailing: Text(item["time"] ?? ""),
              );
            },
          );
        },
      ),
    );
  }
}
