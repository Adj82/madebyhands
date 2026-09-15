import 'package:flutter/material.dart';
import 'package:madebyhands/features/home/presentation/ui/home_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top illustration section
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Center(
                // Placeholder for the illustration (Hands holding phone with infinity symbol)
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Placeholder for the infinity/illustration
                          Container(
                            width: constraints.maxWidth * 0.8,
                            height: constraints.maxHeight * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.white24,
                                size: 80,
                              ),
                            ),
                          ),
                          // Text indicating what goes here
                          const Positioned(
                            bottom: 20,
                            child: Text(
                              'Illustration Placeholder',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Bottom white section with rounded top
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(300, 100),
                  topRight: Radius.elliptical(300, 100),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'Ready, Set, Save!',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Google Sign-In Button
                  InkWell(
                    onTap: () {
                      // Navigate to Landing Page (Home)
                      Navigator.push(context, HomePage.route());
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Icon
                            Image.asset(
                              'assets/images/icon_google.png',
                              height: 28,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.g_mobiledata, size: 40, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Footer text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      children: [
                        Text(
                          'By continuing you agree MadeByHands',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Terms of services & Privacy Policy',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
