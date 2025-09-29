import 'package:supabase_flutter/supabase_flutter.dart';

class Favorite {
  final String userId;
  final String videoId;
  final DateTime createdAt;

  Favorite({
    required this.userId,
    required this.videoId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'video_id': videoId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FavoriteVideo {
  final String id;
  final String videoId;
  final String thumbhash;
  final String title;
  final String category;
  final String categorySlug;
  final DateTime favoritedAt;

  FavoriteVideo({
    required this.id,
    required this.videoId,
    required this.thumbhash,
    required this.title,
    required this.category,
    required this.categorySlug,
    required this.favoritedAt,
  });

  factory FavoriteVideo.fromJson(Map<String, dynamic> json) {
    return FavoriteVideo(
      id: json['id'] as String,
      videoId: json['video_id'] as String,
      thumbhash: json['thumbhash'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      categorySlug: json['category_slug'] as String,
      favoritedAt: DateTime.parse(json['favorited_at'] as String),
    );
  }
}

class PaginatedFavoriteResult {
  final List<FavoriteVideo> data;
  final bool hasMore;
  final int total;

  PaginatedFavoriteResult({
    required this.data,
    required this.hasMore,
    required this.total,
  });
}

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's favorite videos with pagination
  Future<PaginatedFavoriteResult> getFavoritesVideosByUser({
    required String userId,
    int page = 0,
    int limit = 10,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    print(
      'Getting favorites - userId: $userId, limit: $limit, page: $page',
    );

    try {
      // Get total count of user's favorites
      final countResponse = await _supabase
          .from('user_favorites')
          .select('video_id')
          .eq('user_id', userId)
          .count();

      final int totalFavorites = countResponse.count;

      // Get favorite videos with video details, ordered by most recently favorited
      final dataResponse = await _supabase
          .from('user_favorites')
          .select('''
            video_id,
            created_at,
            videos!inner(
              id,
              video_id,
              thumbhash,
              title,
              category,
              category_slug
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> data = dataResponse as List<dynamic>;
      final hasMore = from + data.length < totalFavorites;

      print('Favorites - hasMore: $hasMore');

      final favoriteVideos = data.map((json) {
        final videoData = json['videos'] as Map<String, dynamic>;
        return FavoriteVideo.fromJson({
          'id': videoData['id'],
          'video_id': videoData['video_id'],
          'thumbhash': videoData['thumbhash'],
          'title': videoData['title'],
          'category': videoData['category'],
          'category_slug': videoData['category_slug'],
          'favorited_at': json['created_at'],
        });
      }).toList();

      return PaginatedFavoriteResult(
        data: favoriteVideos,
        hasMore: hasMore,
        total: totalFavorites,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user favorites: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching user favorites: $e');
    }
  }

  /// Get total number of likes for a specific video across all users
  Future<int> getTotalLikedVideosByAllUsers(String videoId) async {
    print('Getting total likes for video: $videoId');

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('user_id')
          .eq('video_id', videoId)
          .count();

      final int totalLikes = response.count;

      print('Total likes for video $videoId: $totalLikes');

      return totalLikes;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get total likes: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting total likes: $e');
    }
  }

  /// Check if a video is favorited by a user
  Future<bool> isVideoFavorited({
    required String userId,
    required String videoId,
  }) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select('video_id')
          .eq('user_id', userId)
          .eq('video_id', videoId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check favorite status: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error checking favorite status: $e');
    }
  }

  /// Toggle favorite status (add if not exists, remove if exists)
  Future<bool> toggleUserFavorite({
    required String userId,
    required String videoId,
  }) async {
    print('Toggling favorite - userId: $userId, videoId: $videoId');

    try {
      // Check if favorite already exists
      final existingFavorite = await _supabase
          .from('user_favorites')
          .select('video_id')
          .eq('user_id', userId)
          .eq('video_id', videoId)
          .maybeSingle();

      if (existingFavorite != null) {
        // Remove favorite
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('video_id', videoId);

        print('Favorite removed');
        return false; // Indicates video was unfavorited
      } else {
        // Add favorite
        await _supabase.from('user_favorites').insert({
          'user_id': userId,
          'video_id': videoId,
        });

        print('Favorite added');
        return true; // Indicates video was favorited
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle favorite: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error toggling favorite: $e');
    }
  }
}