import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MediumNativeAds extends StatefulWidget {
  const MediumNativeAds({super.key});

  @override
  State<MediumNativeAds> createState() {
    return _MediumNativeAdsState();
  }
}

class _MediumNativeAdsState extends State<MediumNativeAds> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  // TODO: replace this test ad unit with your own ad unit.
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3575247302643565/7633969430'
      : 'ca-app-pub-3575247302643565/2817876586';

  /// Loads a native ad.
  void loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Dispose the ad here to free resources.
          print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
        // Called when a click is recorded for a NativeAd.
        onAdClicked: (ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (ad) {},
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (ad) {},
        // For iOS only. Called before dismissing a full screen view
        onAdWillDismissScreen: (ad) {},
        // Called when an ad receives revenue value.
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
      ),
      request: const AdRequest(),
      // Styling
      nativeTemplateStyle: NativeTemplateStyle(
        // Required: Choose a template.
        templateType: TemplateType.small,
      ),
    )..load();
  }

  @override
  void initState() {
    loadAd();
    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    
    return _nativeAdIsLoaded ? ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320, // minimum recommended width
        minHeight: 90, // minimum recommended height
        maxWidth: 400,
        maxHeight: 200,
      ),
      child: AdWidget(ad: _nativeAd!),
    ): Text("Not loaded");
  }
}
