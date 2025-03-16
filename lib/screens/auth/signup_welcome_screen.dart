import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SignupWelcomeScreen extends StatefulWidget {
  const SignupWelcomeScreen({super.key});

  @override
  State<SignupWelcomeScreen> createState() => _SignupWelcomeScreenState();
}

class _SignupWelcomeScreenState extends State<SignupWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _welcomeData = [
    {
      'image': 'assets/pic1.png',
      'title': 'Connect',
      'description': 'Join your campus community and make new friends',
    },
    {
      'image': 'assets/pic-1.png',
      'title': 'Share',
      'description': 'Share your thoughts, events, and discoveries',
    },
    {
      'image': 'assets/pic-2.png',
      'title': 'Discover',
      'description': 'Stay updated with campus events and activities',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _welcomeData.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final data = _welcomeData[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration
                      Image.asset(
                        data['image']!,
                        height: MediaQuery.of(context).size.height * 0.4,
                      ),
                      const SizedBox(height: 40),
                      // Title with animated slide
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Text(
                                data['title']!,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description with animated fade
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                data['description']!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _welcomeData.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      type: WormType.thin,
                      activeDotColor: theme.colorScheme.primary,
                      dotColor: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: Text(
                        _currentPage == _welcomeData.length - 1 ? 'Get Started' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
