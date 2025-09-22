import 'package:flutter/material.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toonplay/widgets/ads/medium_native_ads.dart';

class IntroCard extends StatelessWidget {
  const IntroCard({
    super.key,
    required this.cardImage,
    required this.cardTitle,
  });

  final String cardImage;
  final String cardTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Positioned(
              top: 1.5,
              child: Text(
                cardTitle,
                style: GoogleFonts.fredoka(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ),
            Text(
              cardTitle,
              style: GoogleFonts.fredoka(
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: 4.0),
            ),
          ),
          child: Image.asset(cardImage, height: double.infinity),
        ),
      ],
    );
  }
}
