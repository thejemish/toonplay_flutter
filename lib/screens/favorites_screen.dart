import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:toonplay/supabase/favorites_service.dart';
import 'package:toonplay/supabase/video_service.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/widgets/category_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FavoritesScreenState();
  }
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final _pagingController = PagingController<int, FavoriteVideo>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => _fetchFavoriteVideos(pageKey - 1),
  );

  final FavoritesService _favoritesService = FavoritesService();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _pageSize = 10;

  Future<List<FavoriteVideo>> _fetchFavoriteVideos(int pageKey) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final result = await _favoritesService.getFavoritesVideosByUser(
        userId: userId,
        page: pageKey,
        limit: _pageSize,
      );
      
      return result.data;
    } catch (error) {
      throw Exception('Failed to fetch favorites: $error');
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
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
                    padding: EdgeInsetsDirectional.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Favorites',
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
                PagedSliverList<int, FavoriteVideo>.separated(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  builderDelegate: PagedChildBuilderDelegate<FavoriteVideo>(
                    itemBuilder: (context, item, index) {
                      final isEvenIndex = index % 2 == 0;
                      final nextIndex = index + 1;
                      final hasNextItem = state.items != null &&
                          nextIndex < state.items!.length;

                      // Only build rows for even indices to avoid duplicates
                      if (!isEvenIndex) return const SizedBox.shrink();

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left card
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: AppSpacing.xs),
                              child: _buildFavoriteCard(item),
                            ),
                          ),
                          // Right card (if exists)
                          if (hasNextItem)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: AppSpacing.xs),
                                child: _buildFavoriteCard(
                                    state.items![nextIndex]),
                              ),
                            ),
                          // Empty space if no right card
                          if (!hasNextItem) const Expanded(child: SizedBox()),
                        ],
                      );
                    },
                    noItemsFoundIndicatorBuilder: (context) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'No favorites yet',
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Start adding videos to your favorites!',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    firstPageErrorIndicatorBuilder: (context) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.red,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Failed to load favorites',
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            ElevatedButton(
                              onPressed: () => _pagingController.refresh(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                              ),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
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
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteVideo favoriteVideo) {
    return CategoryCard(
      video: _convertToVideo(favoriteVideo),
      onTap: () {
        context.go(
          '/home/short/${favoriteVideo.categorySlug}',
          extra: {
            "data": {
              "category_name": favoriteVideo.category,
              "video_id": favoriteVideo.videoId,
            },
          },
        );
      },
    );
  }

  // Helper method to convert FavoriteVideo to Video
  Video _convertToVideo(FavoriteVideo favoriteVideo) {
    return Video(
      id: favoriteVideo.id,
      videoId: favoriteVideo.videoId,
      thumbhash: favoriteVideo.thumbhash,
      title: favoriteVideo.title,
      category: favoriteVideo.category,
      categorySlug: favoriteVideo.categorySlug,
    );
  }
}