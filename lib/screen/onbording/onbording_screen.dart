import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/login/phone_login.dart';

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
          "Lorem Ipsum is simply dummy text of the printing\nand typesetting industry. Lorem Ipsum Lorem\nIpsum is simply dummy text",
      image: AppOnbordImages.onbord1,
    ),
    OnboardingPageData(
      title: "Discover",
      description:
            "Lorem Ipsum is simply dummy text of the printing\nand typesetting industry. Lorem Ipsum Lorem\nIpsum is simply dummy text",
      image: AppOnbordImages.onbord3,
    ),
    OnboardingPageData(
      title: "Discover",
      description:
           "Lorem Ipsum is simply dummy text of the printing\nand typesetting industry. Lorem Ipsum Lorem\nIpsum is simply dummy text",
      image: AppOnbordImages.onbord2,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
    
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PhoneLogin()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo and tagline
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 2),
              child: Column(
                children: [
                  Image.asset(
                    AppImages.logo,
                    width: AppHeights.logoWidth,
                    height: AppHeights.logoHeight,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Electric vehicle charging station for everyone.\nDiscover. Charge. Pay.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textColor),
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
                  );
                },
              ),
            ),

            // Pagination indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
            SizedBox(height: 20),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

  const OnboardingPageWidget({
    super.key,
    required this.pageData,
    required this.pageIndex,
    required this.currentPage,
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
    return Column(
      children: [
        // Animated illustration - no padding
        SizedBox(
          height: 350,
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

        const SizedBox(height: 30),

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
                  fontSize: 24,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

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
                style: TextStyle(fontSize: 14, color: AppColors.textColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
