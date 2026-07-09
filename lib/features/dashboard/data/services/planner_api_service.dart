import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_calendar_model.dart';
import '../../../../core/config/env_config.dart';

class PlannerApiService {
  final String baseUrl;

  PlannerApiService({String? baseUrl}) : baseUrl = baseUrl ?? EnvConfig.baseUrl;

  Future<ContentCalendarModel?> generateCalendar({
    required String niche,
    required String audience,
    required String goal,
    required String frequency,
    Function(String)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/generate-calendar');
      debugPrint('[API REQUEST] $uri');

      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = json.encode({
          'niche': niche,
          'audience': audience,
          'goal': goal,
          'frequency': frequency,
        });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        debugPrint('ReelIQ: Server returned error status code: ${response.statusCode}');
        return null;
      }

      ContentCalendarModel? finalModel;

      await for (var chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final dataStr = chunk.substring(6);
          try {
            final data = json.decode(dataStr);
            if (data['status'] == 'progress' && onProgress != null) {
              onProgress(data['message'] ?? '');
            } else if (data['status'] == 'complete') {
              final payload = data['data'];
              final calendarId = payload['id'] ?? 'cal_${DateTime.now().millisecondsSinceEpoch}';
              finalModel = ContentCalendarModel.fromJson(payload, docId: calendarId);
            } else if (data['status'] == 'error') {
              throw Exception(data['message'] ?? 'Unknown API error');
            }
          } catch (e) {
            debugPrint('Error parsing SSE chunk: $e\nChunk: $dataStr');
          }
        }
      }

      client.close();
      return finalModel;
    } catch (e) {
      debugPrint('ReelIQ Warning: Calendar API error: $e. Returning null.');
      return null;
    }
  }
}
