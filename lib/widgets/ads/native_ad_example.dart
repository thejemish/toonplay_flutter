import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdExample extends StatefulWidget {
  @override
  _NativeAdExampleState createState() => _NativeAdExampleState();
}

class _NativeAdExampleState extends State<NativeAdExample> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  // Test ad unit IDs - replace with your actual ad unit IDs before publishing
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'  // Android test ad unit
      : 'ca-app-pub-3940256099942544/3986624511'; // iOS test ad unit

  @override
  void initState() {
    super.initState();
    loadAd();
  }

  /// Loads a native ad
  void loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      // Factory ID registered in your MainActivity
      factoryId: 'adFactoryExample',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
        onAdClicked: (ad) {
          print('$NativeAd clicked.');
        },
        onAdImpression: (ad) {
          print('$NativeAd impression occurred.');
        },
        onAdClosed: (ad) {
          print('$NativeAd closed.');
        },
        onAdOpened: (ad) {
          print('$NativeAd opened.');
        },
        onAdWillDismissScreen: (ad) {
          print('$NativeAd will dismiss screen.');
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('$NativeAd paid event: $valueMicros $currencyCode.');
        },
      ),
      request: const AdRequest(),
      // Optional: Pass custom options to your native ad factory implementation
      customOptions: const {'custom-option-1': 'custom-value-1'},
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Native Ad Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This is some content above the native ad.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            // Native Ad Container
            if (_nativeAdIsLoaded && _nativeAd != null)
              Container(
                height: 320, // Adjust height based on your ad layout
                margin: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: AdWidget(ad: _nativeAd!),
              )
            else
              Container(
                height: 320,
                margin: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: _nativeAdIsLoaded 
                      ? Text('Ad failed to load') 
                      : CircularProgressIndicator(),
                ),
              ),
            Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This is some content below the native ad.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            // Reload Ad Button
            ElevatedButton(
              onPressed: () {
                _nativeAd?.dispose();
                setState(() {
                  _nativeAdIsLoaded = false;
                });
                loadAd();
              },
              child: Text('Reload Ad'),
            ),
          ],
        ),
      ),
    );
  }
}