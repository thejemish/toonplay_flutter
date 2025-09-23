import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/supabase/video_category_service.dart';
import 'package:toonplay/supabase/video_service.dart';
import 'package:toonplay/widgets/home_card.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key, required this.category, required this.index});

  final VideoCategory category;
  final int index;

  @override
  State<CategoryList> createState() {
    return _CategoryListState();
  }
}

class _CategoryListState extends State<CategoryList> {
  final VideoService _videoService = VideoService();
  Future<List<Video>>? videosByCategory;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVideosByCategory();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  Future<void> _fetchVideosByCategory() async {
    // Check if widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _videoService.getVideosByCategory(
        categorySlug: widget.category.slug,
        page: 0,
        limit: 5,
      );

      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        videosByCategory = Future.value(result.data);
        isLoading = false;
      });
    } catch (error) {
      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to fetch videos: $error';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final VideoCategory category = widget.category;
    final String categorySlug = category.slug;
    return Container(
      decoration: BoxDecoration(
        // color: Colors.red
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                category.name,
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(30, 32),
                  fixedSize: Size(90, 0),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: EdgeInsets.all(0),
                ),
                onPressed: () {
                  context.go(
                    '/home/category/$categorySlug',
                    extra: {"category_name": category.name},
                  );
                },
                child: Text(
                  "View All",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 285,
            child: FutureBuilder(
              future: videosByCategory,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Something wen wrong',
                      style: GoogleFonts.nunito(
                        color: AppColors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final videos = snapshot.data ?? [];

                  return ListView.separated(
                    itemCount: videos.length,
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                        width: AppSpacing.sm,
                      ); // Or Divider(), or any other separator widget
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final video = videos[index];

                      return HomeCard(video: video);
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FirstPageErrorIndicator extends StatelessWidget {
  final dynamic error;
  final VoidCallback onTryAgain;

  const FirstPageErrorIndicator({
    super.key,
    required this.error,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTryAgain,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class NewPageErrorIndicator extends StatelessWidget {
  final dynamic error;
  final VoidCallback onTryAgain;

  const NewPageErrorIndicator({
    super.key,
    required this.error,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Error loading more categories',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onTryAgain,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class FirstPageProgressIndicator extends StatelessWidget {
  const FirstPageProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class NewPageProgressIndicator extends StatelessWidget {
  const NewPageProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class NoItemsFoundIndicator extends StatelessWidget {
  const NoItemsFoundIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Categories Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no active video categories available at the moment.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NoMoreItemsIndicator extends StatelessWidget {
  const NoMoreItemsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No more categories to load',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
