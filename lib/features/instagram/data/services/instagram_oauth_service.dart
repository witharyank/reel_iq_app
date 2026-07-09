import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';

/// Configuration — fill these in from your Meta Developer App dashboard.
/// See: https://developers.facebook.com/apps/
class InstagramOAuthConfig {
  /// Your Meta App ID from https://developers.facebook.com/apps/
  static const String appId = '977804481904709';

  /// OAuth redirect URI registered in your Meta App dashboard.
  /// Must be HTTPS and exactly match what's in the developer console.
  static const String redirectUri = 'https://reeliq.app/auth/instagram/callback';

  /// Scopes requested from the Instagram Basic Display API.
  static const List<String> scopes = [
    'instagram_basic',
    'instagram_content_publish',
    'pages_show_list',
    'pages_read_engagement',
  ];

  static String get authorizeUrl {
    final url = 'https://www.facebook.com/v19.0/dialog/oauth'
        '?client_id=$appId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&scope=${scopes.join(',')}'
        '&response_type=code';
    debugPrint('--- META OAUTH DEBUG ---');
    debugPrint('OAuth URL: $url');
    debugPrint('App ID: $appId');
    debugPrint('Redirect URI: $redirectUri');
    debugPrint('------------------------');
    return url;
  }
}

/// Result returned after a successful OAuth token exchange.
class InstagramTokenResult {
  final String accessToken;
  final String tokenType;
  final int? expiresIn;
  final String userId;

  InstagramTokenResult({
    required this.accessToken,
    required this.tokenType,
    this.expiresIn,
    required this.userId,
  });
}

/// Handles the real Instagram Graph API OAuth 2.0 flow and data fetching.
///
/// IMPORTANT: Real Instagram connection requires:
/// 1. A Meta Developer account at https://developers.facebook.com
/// 2. An App with Instagram Basic Display API enabled
/// 3. Approved permissions: instagram_basic
/// 4. Registered redirect URI matching [InstagramOAuthConfig.redirectUri]
/// 5. App Review approval for production (development mode works without it)
///
/// In mock mode, this service is never instantiated — MockInstagramService handles all calls.
class InstagramOAuthService {
  static const String _graphBase = 'https://graph.instagram.com';
  static const String _oauthBase = 'https://api.instagram.com';

  // Set this to true if testing on Android Emulator, false if testing on physical Android device
  static const bool _isEmulator = false;

  /// Generates the OAuth authorization URL to open in a WebView.
  String getAuthorizeUrl() => InstagramOAuthConfig.authorizeUrl;

  /// Exchanges an authorization code for a long-lived access token via the backend.
  Future<InstagramTokenResult> exchangeCodeForToken(String code) async {
    final baseUrl = _getBaseUrl();
    final uri = Uri.parse('$baseUrl/instagram/exchange-token');
    debugPrint('[API REQUEST] $uri');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'redirect_uri': InstagramOAuthConfig.redirectUri,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend token exchange failed: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return InstagramTokenResult(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String? ?? 'bearer',
      expiresIn: data['expires_in'] as int?,
      userId: data['user_id'] as String,
    );
  }

  static String _getBaseUrl() {
    return EnvConfig.baseUrl;
  }

  /// Fetches the authenticated user's Instagram profile via backend proxy.
  Future<Map<String, dynamic>> fetchUserProfile(String accessToken) async {
    final baseUrl = _getBaseUrl();
    final uri = Uri.parse('$baseUrl/instagram/profile?access_token=$accessToken');
    debugPrint('[API REQUEST] $uri');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Instagram profile via proxy: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Fetches the user's recent media (reels/posts) via backend proxy.
  Future<List<Map<String, dynamic>>> fetchUserMedia(String accessToken,
      {int limit = 25}) async {
    final baseUrl = _getBaseUrl();
    final uri = Uri.parse('$baseUrl/instagram/media?access_token=$accessToken&limit=$limit');
    debugPrint('[API REQUEST] $uri');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Instagram media via proxy: ${response.body}');
    }

    final items = json.decode(response.body) as List<dynamic>;
    return items.map((item) => item as Map<String, dynamic>).toList();
  }

  /// Sends profile and media data to the backend to get AI insights.
  Future<Map<String, dynamic>> analyzeProfile(Map<String, dynamic> profileData, List<Map<String, dynamic>> mediaData) async {
    final baseUrl = _getBaseUrl();
    final uri = Uri.parse('$baseUrl/instagram/analyze-profile');
    debugPrint('[API REQUEST] $uri');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'profile_data': profileData,
        'media_data': mediaData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to analyze profile: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Refreshes a long-lived token before it expires.
  Future<String> refreshToken(String accessToken) async {
    final response = await http.get(
      Uri.parse(
          '$_graphBase/refresh_access_token'
          '?grant_type=ig_refresh_token'
          '&access_token=$accessToken'),
    );

    if (response.statusCode != 200) {
      debugPrint('Token refresh failed: ${response.body}');
      return accessToken; // Return existing token as fallback
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String? ?? accessToken;
  }
}
