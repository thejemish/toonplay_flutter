import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:toonplay/supabase/video_service.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/widgets/category_card.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({
    super.key,
    required this.slug,
    required this.categoryName,
  });

  final String slug;
  final String categoryName;

  @override
  State<StatefulWidget> createState() {
    return _CategoryListState();
  }
}

class _CategoryListState extends State<CategoryListScreen> {
  late final _pagingController = PagingController<int, Video>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => _fetchVideosByCategory(pageKey - 1),
  );

  final VideoService _videoService = VideoService();
  static const _pageSize = 3;

  Future<List<Video>> _fetchVideosByCategory(int pageKey) async {
    try {
      final result = await _videoService.getVideosByCategory(
        page: pageKey,
        limit: _pageSize,
        categorySlug: widget.slug,
      );
      return result.data;
    } catch (error) {
      throw Exception('Failed to fetch categories: $error');
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: PagingListener(
          controller: _pagingController,
          builder: (context, state, fetchNextPage) => CustomScrollView(
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: Container(
                  width: 200,
                  // color: Colors.red,
                  padding: EdgeInsetsDirectional.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.categoryName,
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
                          context.go('/home/');
                        },
                        child: Text(
                          "Go Back",
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Paginated list with automatic separators
              PagedSliverList<int, Video>.separated(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<Video>(
                  itemBuilder: (context, item, index) {
                    final isEvenIndex = index % 2 == 0;
                    final nextIndex = index + 1;
                    final hasNextItem =
                        state.items != null && nextIndex < state.items!.length;

                    // Only build rows for even indices to avoid duplicates
                    if (!isEvenIndex) return const SizedBox.shrink();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left card
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: AppSpacing.xs),
                            child: CategoryCard(
                              video: item,
                              onTap: () {
                                context.go(
                                  '/home/short/${widget.slug}',
                                  extra: {
                                    "data": {
                                      "category_name": item.category,
                                      "video_id": item.videoId,
                                    },
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        // Right card (if exists)
                        if (hasNextItem)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: AppSpacing.xs),
                              child: CategoryCard(
                                video: state.items![nextIndex],
                                onTap: () {
                                  context.go(
                                    '/home/short/${widget.slug}',
                                    extra: {
                                      "data": {
                                        "category_name": state.items![nextIndex].category,
                                        "video_id": state.items![nextIndex].videoId,
                                      },
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        // Empty space if no right card
                        if (!hasNextItem) const Expanded(child: SizedBox()),
                      ],
                    );
                  },
                ),
                separatorBuilder: (context, index) {
                  // Only show separator after even indices (complete rows)
                  if (index % 2 == 0) {
                    return Container(
                      width: double.infinity,
                      height: 60,
                      margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          'Advertisement Space',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
