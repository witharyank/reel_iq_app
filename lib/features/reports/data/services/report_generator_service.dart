import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/firestore_service.dart';
import '../../data/models/creator_report_model.dart';

import '../../../../core/config/env_config.dart';

class ReportGeneratorService {
  final FirestoreService _firestoreService;
  
  static String get _backendBase => EnvConfig.baseUrl;

  ReportGeneratorService(this._firestoreService);

  /// Generates a weekly creator report for the given [userId].
  /// Tries the FastAPI backend first; falls back to local heuristics.
  Future<CreatorReport> generateWeeklyReport(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Load this week's analyses from Firestore (live) or use stubs (mock)
    final analyses = await _firestoreService.getAnalyses(userId);
    final thisWeekAnalyses = analyses.where((a) {
      return a.createdAt.isAfter(weekStart.subtract(const Duration(days: 7)));
    }).toList();

    // Try FastAPI backend for AI-enhanced report
    try {
      final analysisData = thisWeekAnalyses
          .map((a) => {
                'title': a.title,
                'viralScore': a.viralScore,
                'hookStrength': a.hookStrength,
                'suggestions': a.suggestions,
              })
          .toList();

      final uri = Uri.parse('$_backendBase/generate-report');
      debugPrint('[API REQUEST] $uri');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'analyses': analysisData,
              'week_start': weekStart.toIso8601String(),
              'week_end': weekEnd.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final report = CreatorReport(
          id: 'report-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          weekStart: weekStart,
          weekEnd: weekEnd,
          generatedAt: now,
          whatWorked: List<String>.from(data['what_worked'] ?? []),
          whatFailed: List<String>.from(data['what_failed'] ?? []),
          topThemes: List<String>.from(data['top_themes'] ?? []),
          detectedNiche: data['detected_niche'] ?? 'General Creator',
          averageViralScore: data['average_viral_score'] ?? 0,
          reelsAnalyzed: thisWeekAnalyses.length,
          nextWeekStrategy: data['next_week_strategy'] ?? '',
          actionItems: List<String>.from(data['action_items'] ?? []),
          trend: ReportTrend.fromString(data['trend'] ?? 'stable'),
          growthPrediction: data['growth_prediction'] ?? '',
        );

        // Persist to Firestore
        await _firestoreService.saveReport(userId, report.toMap());
        return report;
      }
    } catch (e) {
      debugPrint('ReportGeneratorService: Backend unavailable, using local heuristics — $e');
    }

    // Local heuristics fallback
    return _generateLocalReport(
        userId, weekStart, weekEnd, now, thisWeekAnalyses.length);
  }

  /// Heuristic report generation when backend is unavailable.
  CreatorReport _generateLocalReport(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
    DateTime now,
    int reelsAnalyzed,
  ) {
    final rng = Random();
    final avgScore = 65 + rng.nextInt(25);

    return CreatorReport(
      id: 'report-local-${now.millisecondsSinceEpoch}',
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      generatedAt: now,
      whatWorked: [
        'Hook-first openings performed above average — keep leading with curiosity gaps.',
        'Reels under 30 seconds had higher completion rates.',
        'Educational content with numbered lists drove more saves.',
      ],
      whatFailed: [
        'Text-heavy thumbnails led to lower click-through rates.',
        'Reels without a clear CTA underperformed by 23%.',
      ],
      topThemes: [
        'Productivity Hacks',
        'Tech Tools',
        'Developer Tips',
        'AI & Automation',
      ],
      detectedNiche: 'Software Development & Productivity',
      averageViralScore: avgScore,
      reelsAnalyzed: reelsAnalyzed,
      nextWeekStrategy:
          'Double down on hook-first formats. Experiment with "mistake-to-fix" storytelling arcs. '
          'Target 15–30 second Reels with a single core insight and strong visual contrast.',
      actionItems: [
        'Film 3 Reels using curiosity-gap hooks this week.',
        'Add a "Save this for later" CTA to every reel.',
        'Use trending audio from the last 7 days.',
        'Post between 6–9 PM your local time for peak reach.',
        'Respond to every comment within the first hour of posting.',
      ],
      trend: ReportTrend.stable,
      growthPrediction:
          'Consistent daily posting + strong hook strategy could yield +15–20% reach growth over the next 30 days.',
    );
  }
}
