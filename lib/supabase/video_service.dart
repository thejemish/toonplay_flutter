import 'package:supabase_flutter/supabase_flutter.dart';

class Video {
  final String id;
  final String videoId;
  final String thumbhash;
  final String title;
  final String category;
  final String categorySlug;

  Video({
    required this.id,
    required this.videoId,
    required this.thumbhash,
    required this.title,
    required this.category,
    required this.categorySlug,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      videoId: json['video_id'] as String,
      thumbhash: json['thumbhash'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      categorySlug: json['category_slug'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_id': videoId,
      'thumbhash': thumbhash,
      'title': title,
      'category': category,
      'category_slug': categorySlug,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Video &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Video{id: $id, videoId: $videoId, title: $title, category: $category}';
  }
}

class PaginatedVideoResult {
  final List<Video> data;
  final bool hasMore;
  final int total;

  PaginatedVideoResult({
    required this.data,
    required this.hasMore,
    required this.total,
  });
}

class VideoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get a single video by video_id
  Future<Video?> getVideoById(String videoId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select('id, video_id, thumbhash, title, category, category_slug')
          .eq('video_id', videoId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Video.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch video: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching video: $e');
    }
  }

  /// Get random videos with pagination
  Future<PaginatedVideoResult> getRandomVideos({
    int page = 0,
    int limit = 10,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    print('Getting random videos - limit: $limit, page: $page');

    try {
      // Get total count of videos
      final countResponse = await _supabase
          .from('videos')
          .select('id')
          .count();

      final int totalVideos = countResponse.count;

      // Get random videos using ORDER BY RANDOM()
      final dataResponse = await _supabase
          .from('videos')
          .select('id, video_id, thumbhash, title, category, category_slug')
          .order('random()', ascending: true) // PostgreSQL random function
          .range(from, to);

      final List<dynamic> data = dataResponse as List<dynamic>;
      final hasMore = from + data.length < totalVideos;

      print('Random videos - hasMore: $hasMore');

      final videos = data
          .map((json) => Video.fromJson(json))
          .toList();

      return PaginatedVideoResult(
        data: videos,
        hasMore: hasMore,
        total: totalVideos,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch random videos: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching random videos: $e');
    }
  }

  /// Get videos by category with pagination
  Future<PaginatedVideoResult> getVideosByCategory({
    required String categorySlug,
    int page = 0,
    int limit = 10,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    print('Getting videos by category - categorySlug: $categorySlug, limit: $limit, page: $page');

    try {
      // Get total count of videos in this category
      final countResponse = await _supabase
          .from('videos')
          .select('id')
          .eq('category_slug', categorySlug)
          .count();

      final int totalVideos = countResponse.count;

      // Get videos in this category, ordered by title
      final dataResponse = await _supabase
          .from('videos')
          .select('id, video_id, thumbhash, title, category, category_slug')
          .eq('category_slug', categorySlug)
          .order('title', ascending: true)
          .range(from, to);

      final List<dynamic> data = dataResponse as List<dynamic>;
      final hasMore = from + data.length < totalVideos;

      print('Videos by category - hasMore: $hasMore');

      final videos = data
          .map((json) => Video.fromJson(json))
          .toList();

      return PaginatedVideoResult(
        data: videos,
        hasMore: hasMore,
        total: totalVideos,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch videos by category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching videos by category: $e');
    }
  }
}