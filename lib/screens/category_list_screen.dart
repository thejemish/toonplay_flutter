import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:toonplay/supabase/video_service.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/widgets/category_card.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key, required this.slug});

  final String slug;

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
                  padding: EdgeInsetsDirectional.only(top: 15, bottom: 10),
                  child: Text('This is header'),
                ),
              ),
              // Paginated list
              PagedSliverGrid<int, Video>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<Video>(
                  itemBuilder: (context, item, index) => CategoryCard(video: item),
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  mainAxisSpacing: AppSpacing.sm, // Remove since you're using padding
                  crossAxisSpacing: AppSpacing.sm, // Remove since you're using padding
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
