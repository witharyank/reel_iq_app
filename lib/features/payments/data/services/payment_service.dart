import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env_config.dart';

class PaymentApiService {
  /// Detects backend base URL (same pattern as other services in this app)
  String _getBaseUrl() {
    return EnvConfig.baseUrl;
  }

  /// Creates a Razorpay subscription via the backend
  Future<Map<String, dynamic>> createSubscription({
    required String userId,
  }) async {
    final url = '${_getBaseUrl()}/payments/create-subscription';
    debugPrint('[PaymentApiService] Creating subscription: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
      }),
    );

    debugPrint('[PaymentApiService] Create subscription response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create subscription: ${response.body}');
    }
  }

  /// Verifies subscription Google Play purchase token via the backend
  Future<Map<String, dynamic>> verifySubscription({
    required String purchaseToken,
    required String productId,
    required String userId,
  }) async {
    final url = '${_getBaseUrl()}/payments/verify-google-play';
    debugPrint('[PaymentApiService] Verifying subscription: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'purchase_token': purchaseToken,
        'product_id': productId,
        'user_id': userId,
      }),
    );

    debugPrint('[PaymentApiService] Verify response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Subscription verification failed: ${response.body}');
    }
  }
}
