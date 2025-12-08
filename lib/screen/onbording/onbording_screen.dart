import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/login/phone_login.dart';
import 'package:onecharge/utils/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Discover",
      description:
          "From low battery to flat tyres — OneCharge\ngets you moving again, fast.",
      image: AppOnbordImages.onbord1,
    ),
    OnboardingPageData(
      title: "Discover",
      description:
            "Book mechanical help, battery swaps, or\ntowing with one app",
      image: AppOnbordImages.onbord3,
    ),
    OnboardingPageData(
      title: "Discover",
      description:
           "Share your issue with photos or video\n— we handle the rest.",
      image: AppOnbordImages.onbord2,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding as completed
      await OnboardingService.completeOnboarding();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PhoneLogin()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo and tagline
            Padding(
              padding: EdgeInsets.only(
                top: isSmallScreen ? 10 : 20,
                bottom: 2,
                left: 16,
                right: 16,
              ),
              child: Column(
                children: [
                  Image.asset(
                    AppImages.logo,
                    width: AppHeights.logoWidth,
                    height: AppHeights.logoHeight,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    "OneCharge delivers quick, reliable EV support\nanytime you need it.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),

            // PageView for onboarding pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(
                    pageData: _pages[index],
                    pageIndex: index,
                    currentPage: _currentPage,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    isSmallScreen: isSmallScreen,
                    isLargeScreen: isLargeScreen,
                  );
                },
              ),
            ),

            // Pagination indicators
            Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.textColor
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),

            // Continue button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isSmallScreen ? 12 : 20,
              ),
              child: OneBtn(
                text: _currentPage == _pages.length - 1
                    ? "Get Started"
                    : "Continue",
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String image;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPageData pageData;
  final int pageIndex;
  final int currentPage;
  final double screenHeight;
  final double screenWidth;
  final bool isSmallScreen;
  final bool isLargeScreen;

  const OnboardingPageWidget({
    super.key,
    required this.pageData,
    required this.pageIndex,
    required this.currentPage,
    required this.screenHeight,
    required this.screenWidth,
    required this.isSmallScreen,
    required this.isLargeScreen,
  });

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start animation when page becomes visible
    if (widget.pageIndex == widget.currentPage) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when page becomes active
    if (widget.pageIndex == widget.currentPage &&
        oldWidget.currentPage != widget.currentPage) {
      _animationController.reset();
      _animationController.forward();
    } else if (widget.pageIndex != widget.currentPage) {
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate responsive heights based on screen size
    final imageHeight = widget.isSmallScreen
        ? widget.screenHeight * 0.25
        : widget.isLargeScreen
            ? widget.screenHeight * 0.35
            : widget.screenHeight * 0.30;
    
    final titleSpacing = widget.isSmallScreen ? 20.0 : 30.0;
    final descriptionSpacing = widget.isSmallScreen ? 8.0 : 10.0;
    final titleFontSize = widget.isSmallScreen ? 20.0 : widget.isLargeScreen ? 28.0 : 24.0;
    final descriptionFontSize = widget.isSmallScreen ? 12.0 : widget.isLargeScreen ? 16.0 : 14.0;
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: widget.screenHeight * 0.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration - responsive height
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Align(
                    alignment: widget.pageIndex == 0
                        ? Alignment.centerLeft
                        : widget.pageIndex == 1
                            ? Alignment.centerRight
                            : Alignment.center,
                    child: Image.asset(
                      widget.pageData.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: titleSpacing),

            // Animated title - with padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    widget.pageData.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: descriptionSpacing),

            // Animated description - with padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    widget.pageData.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: descriptionFontSize,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
