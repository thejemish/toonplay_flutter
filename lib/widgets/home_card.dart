import 'package:flutter/material.dart';

import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/supabase/video_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_thumbhash/flutter_thumbhash.dart';

class HomeCard extends StatefulWidget {
  const HomeCard({super.key, required this.video});

  final Video video;

  @override
  State<HomeCard> createState() {
    return _HomeCardState();
  }
}

class _HomeCardState extends State<HomeCard> {
  @override
  Widget build(BuildContext context) {

    final video = widget.video;
    final videoId  = video.videoId;

    final imageUrl =
        'https://ai-video-media.codepick.in/thumbnails/$videoId.webp';

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
          print("Card cliked");
        },
        child: Container(
          width: 150,
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
                  width: 140,
                  height: 200,
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
