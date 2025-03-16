import 'package:flutter/material.dart';
import 'package:unibuzz_community/services/shared_prefs.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _onGetStarted(BuildContext context) async {
    final prefs = await SharedPrefs.instance;
    await prefs.setBool('has_seen_welcome', true);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
                Image.asset(
                  'assets/pic1.png',
                  height: 280,
                ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'UniBUZZ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142), // Dark navy color
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              const Text(
                'Stay in touch with your friends',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6F7D), // Gray color
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _onGetStarted(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE5B4), // Cream yellow color
                    foregroundColor: const Color(0xFF2D3142),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

