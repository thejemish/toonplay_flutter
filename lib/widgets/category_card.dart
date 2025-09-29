import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_thumbhash/flutter_thumbhash.dart';

import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/supabase/video_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryCard extends StatefulWidget {
  const CategoryCard({super.key, required this.video, required this.onTap});

  final Video video;
  final Function onTap;

  @override
  State<CategoryCard> createState() {
    return _CategoryCardState();
  }
}

class _CategoryCardState extends State<CategoryCard> {
  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final videoId = video.videoId;

    final imageUrl =
        'https://ai-video-media.codepick.in/thumbnails/$videoId.webp';

    double cardImageHeight = 250;

    if (ResponsiveBreakpoints.of(context).equals('MOBILE_SMALL')) {
      cardImageHeight = 200;
    } else if (ResponsiveBreakpoints.of(context).equals('MOBILE')) {
      cardImageHeight = 250;
    } else {
      cardImageHeight = 250;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      color: AppColors.card,
      shadowColor: AppColors.textPrimary,
      borderOnForeground: false,
      child: InkWell(
        splashColor: const Color.fromRGBO(255, 210, 105, 0.5),
        onTap: () {
          widget.onTap();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: const Border(
              bottom: BorderSide(color: AppColors.primary, width: 4.0),
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: FadeInImage(
                  image: NetworkImage(imageUrl),
                  placeholder: ThumbHash.fromBase64(video.thumbhash).toImage(),
                  width: double.infinity,
                  height: cardImageHeight,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
