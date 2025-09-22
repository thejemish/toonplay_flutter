import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class SupabaseInstance {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  bool initialize() {
    final sessionDb = Supabase.instance.client.auth.currentSession;
    bool isInitialized = false;

    // print('sessionDb?.user $sessionDb');

    if (sessionDb?.user == null) {
      isInitialized = false;
    } else {
      isInitialized = true;
    }

    return isInitialized;
  }

  Future<void> signInAnonymous() async {
    try {
      var deviceData = <String, dynamic>{};

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
          break;
        case TargetPlatform.iOS:
          deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
          break;
        default:
          break;
      }

      // Wait for the sign in to complete
      final response = await Supabase.instance.client.auth.signInAnonymously(data: deviceData);
      
      if (response.user == null) {
        throw Exception('Failed to sign in anonymously');
      }
      
      print('Anonymous sign in successful: ${response.user?.id}');
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow; // Re-throw the error so it can be handled in the UI
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'name': build.name,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'freeDiskSize': build.freeDiskSize,
      'totalDiskSize': build.totalDiskSize,
      'systemFeatures': build.systemFeatures,
      'isLowRamDevice': build.isLowRamDevice,
      'physicalRamSize': build.physicalRamSize,
      'availableRamSize': build.availableRamSize,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'modelName': data.modelName,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'isiOSAppOnMac': data.isiOSAppOnMac,
      'freeDiskSize': data.freeDiskSize,
      'totalDiskSize': data.totalDiskSize,
      'physicalRamSize': data.physicalRamSize,
      'availableRamSize': data.availableRamSize,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }
}