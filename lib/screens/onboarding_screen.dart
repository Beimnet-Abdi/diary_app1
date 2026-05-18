import 'package:flutter/material.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _buildPage(
                  "Find Your Future",
                  "Browse curated jobs and internships.",
                ),
                _buildPage(
                  "Capture Life",
                  "Store your memories in a beautiful diary.",
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006064),
              minimumSize: const Size(200, 50),
            ),
            onPressed: () {
              if (_index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
            child: Text(
              _index == 1 ? "Get Started" : "Next",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPage(String t, String d) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        t,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text(d, textAlign: TextAlign.center),
      ),
    ],
  );
}
