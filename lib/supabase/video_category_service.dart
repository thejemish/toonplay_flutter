import 'package:supabase_flutter/supabase_flutter.dart';

class VideoCategory {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  VideoCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'is_active': isActive};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VideoCategory{id: $id, name: $name, slug: $slug, isActive: $isActive}';
  }
}

class PaginatedResult<T> {
  final List<VideoCategory> data;
  final bool hasMore;
  final int total;

  PaginatedResult({
    required this.data,
    required this.hasMore,
    required this.total,
  });
}

class VideoCategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<PaginatedResult<VideoCategory>> getCategories({
    int page = 0,
    int limit = 10,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    print('limit $limit');

    try {
      final countResponse = await _supabase
          .from('video_categories')
          .select('id')
          .eq('is_active', true)
          .count();

      final int totalCategories = countResponse.count;

      final dataResponse = await _supabase
          .from('video_categories')
          .select('id, name, slug, is_active')
          .eq('is_active', true)
          .order('name', ascending: true)
          .range(from, to);

      final List<dynamic> data = dataResponse as List<dynamic>;

      final hasMore = from + data.length < totalCategories;

      print('hasMore $hasMore');

      final categories = data
          .map((json) => VideoCategory.fromJson(json))
          .toList();

      return PaginatedResult<VideoCategory>(
        data: categories,
        hasMore: hasMore,
        total: totalCategories,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch categories: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching categories: $e');
    }
  }

  /// Get a single category by slug
  Future<VideoCategory?> getCategoryBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('video_categories')
          .select('id, name, slug, is_active')
          .eq('slug', slug)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return VideoCategory.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching category: $e');
    }
  }
}
