import 'package:flutter/foundation.dart';

class EnvConfig {
  /// The production base URL for your backend API
  static const String _prodBaseUrl = 'https://api.reeliq.app'; // Production URL to be configured in real DNS

  /// Determines the Base URL based on environment
  static String get baseUrl {
    if (kReleaseMode) {
      return _prodBaseUrl;
    }

    // Development URLs
    if (kIsWeb) return 'http://192.168.0.119:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 works for Android Emulator, but 192.168.0.119 works for real devices on LAN
      return 'http://192.168.0.119:8000';
    }
    return 'http://192.168.0.119:8000';
  }
}
