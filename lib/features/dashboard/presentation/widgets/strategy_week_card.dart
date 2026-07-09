import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/content_calendar_model.dart';

class StrategyWeekCard extends StatelessWidget {
  final WeeklyPlan week;

  const StrategyWeekCard({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week ${week.weekNumber} Strategy',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.auto_graph_rounded, color: AppTheme.accent),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.flag_rounded, 'Weekly Goal', week.weeklyGoal),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.lightbulb_outline_rounded, 'Strategy', week.weeklyStrategy),
          const SizedBox(height: 16),
          const Text(
            'Weekly KPIs',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: week.weeklyKPIs.map((kpi) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  kpi,
                  style: const TextStyle(color: AppTheme.primary, fontSize: 11),
                ),
              );
            }).toList(),
          ),
          if (week.growthCoach.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Growth Coach Advice',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (week.growthCoach['improve'] != null)
                    _buildCoachRow(Icons.arrow_upward_rounded, AppTheme.success, 'Improve', week.growthCoach['improve']),
                  if (week.growthCoach['stop'] != null)
                    _buildCoachRow(Icons.block_rounded, AppTheme.error, 'Stop Doing', week.growthCoach['stop']),
                  if (week.growthCoach['trendSuggestion'] != null)
                    _buildCoachRow(Icons.trending_up_rounded, AppTheme.warning, 'Trend Alert', week.growthCoach['trendSuggestion']),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachRow(IconData icon, Color color, String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'Inter'),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
