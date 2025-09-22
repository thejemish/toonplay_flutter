import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdConfigModel {
  final String? adId;
  final String screen;
  final String adType;
  final int adPosition;
  final int maxPages;
  final int pageSize;
  final bool isAdsEnabled;

  AdConfigModel({
    required this.adId,
    required this.screen,
    required this.adType,
    required this.adPosition,
    required this.maxPages,
    required this.pageSize,
    required this.isAdsEnabled,
  });

  factory AdConfigModel.fromJson(Map<String, dynamic> json) {
    // Determine platform and get appropriate ad ID
    final bool isIOS = Platform.isIOS;
    final bool isAndroid = Platform.isAndroid;

    String? adId;
    bool isAdsEnabled = false;

    if (isIOS && json['ios_ad_id'] != null) {
      adId = json['ios_ad_id'] as String;
      isAdsEnabled = true;
    } else if (isAndroid && json['android_ad_id'] != null) {
      adId = json['android_ad_id'] as String;
      isAdsEnabled = true;
    }

    return AdConfigModel(
      adId: adId,
      screen: json['screen'] as String,
      adType: json['ad_type'] as String,
      adPosition: json['ad_position'] as int,
      maxPages: json['max_pages'] as int,
      pageSize: json['page_size'] as int,
      isAdsEnabled: isAdsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ad_id': adId,
      'screen': screen,
      'ad_type': adType,
      'ad_position': adPosition,
      'max_pages': maxPages,
      'page_size': pageSize,
      'is_ads_enabled': isAdsEnabled,
    };
  }

  @override
  String toString() {
    return 'AdConfigModel(adId: $adId, screen: $screen, adType: $adType, '
        'adPosition: $adPosition, maxPages: $maxPages, pageSize: $pageSize, '
        'isAdsEnabled: $isAdsEnabled)';
  }
}

class AdConfigService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get ad configuration by screen name
  Future<AdConfigModel?> getAdConfigByScreen(String screenName) async {
    try {
      final response = await _supabase
          .from('ads_config')
          .select(
            'screen, ad_type, ios_ad_id, android_ad_id, ad_position, max_pages, page_size',
          )
          .eq('screen', screenName)
          .single();

      return AdConfigModel.fromJson(response);
    } catch (e) {
      print('Error fetching ad config for screen $screenName: $e');
      return null;
    }
  }

  /// Check if ads are enabled for a specific screen
  Future<bool> areAdsEnabledForScreen(String screenName) async {
    try {
      final config = await getAdConfigByScreen(screenName);
      return config?.isAdsEnabled ?? false;
    } catch (e) {
      print('Error checking ads status for screen $screenName: $e');
      return false;
    }
  }
}
