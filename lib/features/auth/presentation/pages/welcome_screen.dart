import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingPages = [
    OnboardingData(
      title: 'Crafted with Soul',
      subtitle: 'Discover unique handmade pieces that carry the spirit of the artist who made them.',
      imageUrl: 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?q=80&w=1000&auto=format&fit=crop',
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Stories in Every Thread',
      subtitle: 'Connect with independent Indian artisans and support traditional craftsmanship.',
      imageUrl: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?q=80&w=1000&auto=format&fit=crop',
      color: AppColors.accent,
    ),
    OnboardingData(
      title: 'Experience Authenticity',
      subtitle: 'A marketplace built for creators, by people who value the beauty of the handmade.',
      imageUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=1000&auto=format&fit=crop',
      color: AppColors.primaryDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background Image with crossfade
              AnimatedSwitcher(
                duration: 800.ms,
                child: Container(
                  key: ValueKey(_currentPage),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_onboardingPages[_currentPage].imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.35),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),

              // Glassmorphic Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      AppColors.background.withValues(alpha: 0.95),
                      AppColors.background,
                    ],
                    stops: const [0.0, 0.4, 0.7, 0.85],
                  ),
                ),
              ),

              // Main Content
              Column(
                children: [
                  const SafeArea(child: SizedBox(height: 20)),
                  // Branding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MADEBYHANDS',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2),
                        if (_currentPage < _onboardingPages.length - 1)
                          TextButton(
                            onPressed: () => _pageController.jumpToPage(_onboardingPages.length - 1),
                            child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Animated Text Content
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: _onboardingPages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _onboardingPages[index].title,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: index == _currentPage ? AppColors.text : Colors.white,
                                  height: 1.1,
                                ),
                              ).animate(key: ValueKey('title_$index')).fadeIn(delay: 200.ms).slideY(begin: 0.2),
                              const SizedBox(height: 20),
                              Text(
                                _onboardingPages[index].subtitle,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.mutedText,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ).animate(key: ValueKey('sub_$index')).fadeIn(delay: 400.ms).slideY(begin: 0.2),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 50),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: _onboardingPages.length,
                              effect: const ExpandingDotsEffect(
                                activeDotColor: AppColors.primary,
                                dotColor: AppColors.outline,
                                dotHeight: 8,
                                dotWidth: 8,
                                spacing: 10,
                              ),
                            ),
                            
                            // Action Button
                            _currentPage == _onboardingPages.length - 1
                                ? const SizedBox.shrink()
                                : FloatingActionButton.large(
                                    onPressed: () => _pageController.nextPage(
                                      duration: 600.ms,
                                      curve: Curves.easeInOut,
                                    ),
                                    backgroundColor: AppColors.primary,
                                    elevation: 0,
                                    child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                                  ).animate().scale().fadeIn(),
                          ],
                        ),

                        if (_currentPage == _onboardingPages.length - 1)
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
                                icon: state is AuthLoading
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      )
                                    : Image.asset('assets/images/icon_google.png', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.login)),
                                label: const Text('Continue with Google'),
                              ).animate().slideY(begin: 0.5).fadeIn(),
                              const SizedBox(height: 20),
                              Text(
                                'By joining, you agree to our Terms and Conditions',
                                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.color,
  });
}
