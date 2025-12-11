import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';

class DetailPage extends StatefulWidget {
  final String question;
  final String answer;

  const DetailPage({
    super.key,
    required this.answer,
    required this.question,
  });

  @override
  State<StatefulWidget> createState() {
    return _DetailPage();
  }
}

class _DetailPage extends State<DetailPage> {
  BannerAd? _bannerAd;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // AdMob 배너 로드 (테스트 ID)
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-3940256099942544/6300978111",
      listener: BannerAdListener(),
      request: const AdRequest(),
    )..load();

    // Confetti
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _shareResult() {
    // 안드로이드 공유 시에 카카오톡 설치되어 있으면 카톡도 뜸
    Share.share(
      "📌 ${widget.question}\n\n➡ ${widget.answer}\n\n나도 이 테스트 해봤어!",
      subject: "심리테스트 결과",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // 🎉 Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 70),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "🎉 결과가 나왔습니다!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.answer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 공유 버튼
              ElevatedButton.icon(
                onPressed: _shareResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  "친구에게 공유하기",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "← 돌아가기",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              const Spacer(),

              // 배너 광고
              if (_bannerAd != null)
                SizedBox(
                  height: _bannerAd!.size.height.toDouble(),
                  width: _bannerAd!.size.width.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
