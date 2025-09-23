import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/supabase/video_category_service.dart';
import 'package:toonplay/widgets/category_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _pagingController = PagingController<int, VideoCategory>(
    getNextPageKey: (state) =>
        state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => _fetchCategories(pageKey - 1),
  );

  final VideoCategoryService _videoCategoryService = VideoCategoryService();
  static const _pageSize = 3;

  Future<List<VideoCategory>> _fetchCategories(int pageKey) async {
    try {
      final result = await _videoCategoryService.getCategories(
        page: pageKey,
        limit: _pageSize,
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
    List<int> list = [1, 2, 3, 4, 5];
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: PagingListener(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) => CustomScrollView(
          slivers: [
            // Header section
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsetsDirectional.only(top: 15, bottom: 10),
                child: CarouselSlider(
                  options: CarouselOptions(
                    enableInfiniteScroll: true,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.20,
                    height: 220,
                  ),
                  items: list
                      .map(
                        (item) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                            color: Colors.red,
                          ),
                          child: Center(child: Text(item.toString())),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            // Paginated list
            PagedSliverList<int, VideoCategory>.separated(
              state: state,
              fetchNextPage: fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<VideoCategory>(
                itemBuilder: (context, item, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: CategoryList(category: item, index: index),
                ),
                firstPageErrorIndicatorBuilder: (context) =>
                    FirstPageErrorIndicator(
                      error: state.error,
                      onTryAgain: fetchNextPage,
                    ),
                newPageErrorIndicatorBuilder: (context) =>
                    NewPageErrorIndicator(
                      error: state.error,
                      onTryAgain: fetchNextPage,
                    ),
                firstPageProgressIndicatorBuilder: (context) =>
                    const FirstPageProgressIndicator(),
                newPageProgressIndicatorBuilder: (context) =>
                    const NewPageProgressIndicator(),
                noItemsFoundIndicatorBuilder: (context) =>
                    const NoItemsFoundIndicator(),
                noMoreItemsIndicatorBuilder: (context) =>
                    const NoMoreItemsIndicator(),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 0),
            ),
          ],
        ),
      ),
    );
  }
}
