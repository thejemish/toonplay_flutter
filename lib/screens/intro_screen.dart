import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/widgets/intro_card.dart';
import 'package:toonplay/supabase/db_instance.dart';
import 'package:toonplay/supabase/ad_config_service.dart';

class IntroItem {
  final int id;
  final String title;
  final String img;

  const IntroItem({required this.id, required this.title, required this.img});
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() {
    return _IntroScreenState();
  }
}

class _IntroScreenState extends State<IntroScreen> {
  final CarouselSliderController buttonCarouselController =
      CarouselSliderController();

  @override
  void initState(){
    super.initState();
    final adService = AdConfigService();

    void getAdconfig() async{
      final homeConfig = await adService.getAdConfigByScreen('home');
      print('Home ad config $homeConfig');
    }

    getAdconfig();
  }

  @override
  final List<IntroItem> introData = const [
    IntroItem(
      id: 1,
      title: 'Instant Laughs',
      img: 'assets/images/onboarding-1.png',
    ),
    IntroItem(
      id: 2,
      title: 'Fresh & Funny',
      img: 'assets/images/onboarding-2.png',
    ),
    IntroItem(
      id: 3,
      title: 'Comedy Reloaded',
      img: 'assets/images/onboarding-3.png',
    ),
    IntroItem(
      id: 4,
      title: 'Share the Fun',
      img: 'assets/images/onboarding-1.png',
    ),
  ];

  int slideIndex = 0;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsetsGeometry.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 450,
                  enableInfiniteScroll: false,
                  viewportFraction: 1.0,
                  autoPlay: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      slideIndex = index;
                    });
                    print('onPageChanged $index $reason');
                  },
                ),
                carouselController: buttonCarouselController,
                items: introData
                    .map(
                      (item) =>
                          IntroCard(cardImage: item.img, cardTitle: item.title),
                    )
                    .toList(),
                disableGesture: true,
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.secondary,
                      width: 4.0,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.background,
                    backgroundColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                  ),
                  onPressed: isLoading ? null : () async { // Disable button when loading
                    if (slideIndex != 3) {
                      buttonCarouselController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.linear,
                      );
                    }

                    if (slideIndex == 3) {
                      setState(() {
                        isLoading = true; // Show loading state
                      });
                      
                      print("slideIndex $slideIndex");
                      try {
                        await SupabaseInstance().signInAnonymous(); // Wait for sign in to complete
                        if (mounted) { // Check if widget is still mounted
                          context.go('/home');
                        }
                      } catch (e) {
                        print('Sign in error: $e');
                        if (mounted) {
                          setState(() {
                            isLoading = false; // Reset loading state on error
                          });
                          // Show error message to user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign in failed. Please try again.')),
                          );
                        }
                      }
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading && slideIndex == 3)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                          ),
                        )
                      else
                        Text(
                          slideIndex != 3 ? 'Next' : 'Finish',
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (!isLoading || slideIndex != 3) ...[
                        SizedBox(width: 8), // Space between text and icon
                        Icon(
                          PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                          size: 28,
                        ),
                      ],
                    ],
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