import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../viewmodels/planner_viewmodel.dart';
import '../../data/models/content_calendar_model.dart';

import 'widgets/loading_stages_widget.dart';
import 'widgets/strategy_week_card.dart';
import 'widgets/day_detail_panel.dart';

class ContentPlannerScreen extends StatefulWidget {
  final bool embeddedMode;
  
  const ContentPlannerScreen({super.key, this.embeddedMode = false});

  @override
  State<ContentPlannerScreen> createState() => _ContentPlannerScreenState();
}

class _ContentPlannerScreenState extends State<ContentPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicheController = TextEditingController();
  final _audienceController = TextEditingController();
  final _goalController = TextEditingController();
  
  String _postingFrequency = '3 Reels per week';
  ContentCalendarDay? _selectedDay;
  int _selectedWeek = 1;

  final List<String> _frequencies = [
    '3 Reels per day',
    '2 Reels per day',
    'Daily Reels',
    '5 Reels per week',
    '3 Reels per week',
    '2 Reels per week',
  ];

  @override
  void dispose() {
    _nicheController.dispose();
    _audienceController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _generateCalendar() async {
    if (_formKey.currentState!.validate()) {
      final plannerVM = Provider.of<PlannerViewModel>(context, listen: false);
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
      
      if (!profileVM.isPro && plannerVM.savedCalendars.length >= 2) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('Pro Generation Limit'),
            content: const Text(
              'Free Plan is limited to 2 saved Content Calendars. Upgrade to Pro for ₹199/month to generate unlimited content plans.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  profileVM.toggleSubscription();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                child: const Text('Get Pro (₹199)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      final calendar = await plannerVM.generateNewCalendar(
        niche: _nicheController.text,
        audience: _audienceController.text,
        goal: _goalController.text,
        frequency: _postingFrequency,
      );

      if (calendar != null) {
        if (calendar.days.isNotEmpty) {
          setState(() {
            _selectedWeek = 1;
            _selectedDay = calendar.days.first;
          });
        }
      }
    }
  }

  void _exportPdfStub(ContentCalendarModel calendar) {
    if (calendar.pdfPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF ready at: ${calendar.pdfPath}'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not generated for this calendar.'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plannerVM = Provider.of<PlannerViewModel>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Strategy Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (plannerVM.activeCalendar != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.success),
              onPressed: () => _exportPdfStub(plannerVM.activeCalendar!),
              tooltip: 'Export Strategy PDF',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              onPressed: () {
                plannerVM.deleteCalendar(plannerVM.activeCalendar!.id);
                setState(() {
                  _selectedDay = null;
                });
              },
            ),
          ]
        ],
      ),
      body: plannerVM.isLoading
          ? LoadingStagesWidget(currentStage: plannerVM.loadingStage)
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, widget.embeddedMode ? 44 : 16, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 1200 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (plannerVM.activeCalendar == null)
                        _buildSetupForm()
                      else
                        _buildCalendarDashboard(plannerVM.activeCalendar!, plannerVM),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSetupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Premium Strategy',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our AI will analyze your niche, calculate mathematical frequency, and generate a highly detailed campaign.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 24),
          
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nicheController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'What is your Niche?',
                    hintText: 'e.g. Flutter Development, Personal Finance',
                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your niche' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _audienceController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Who is your Target Audience?',
                    hintText: 'e.g. Student Developers, GenZ Investors',
                    prefixIcon: Icon(Icons.people_alt_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your audience' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _goalController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'What is your Core Goal?',
                    hintText: 'e.g. Get newsletter subscribers, Build brand',
                    prefixIcon: Icon(Icons.flag_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your goal' : null,
                ),
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: _postingFrequency,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: const InputDecoration(
                    labelText: 'Posting Frequency',
                    prefixIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.textSecondary),
                  ),
                  items: _frequencies.map((freq) {
                    return DropdownMenuItem<String>(
                      value: freq,
                      child: Text(freq),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _postingFrequency = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          
          Consumer<PlannerViewModel>(
            builder: (context, plannerVM, _) {
              return ElevatedButton.icon(
                onPressed: plannerVM.isLoading ? null : _generateCalendar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primary,
                ),
                icon: const Icon(Icons.insights_rounded, color: Colors.white),
                label: const Text(
                  'Generate Strategy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDashboard(ContentCalendarModel calendar, PlannerViewModel plannerVM) {
    if (_selectedDay == null && calendar.days.isNotEmpty) {
      _selectedDay = calendar.days.first;
      _selectedWeek = _selectedDay!.weekNumber;
    }

    final isWide = MediaQuery.of(context).size.width > 900;
    
    // Get active week data
    final activeWeekPlan = calendar.weeks.firstWhere(
      (w) => w.weekNumber == _selectedWeek,
      orElse: () => calendar.weeks.first,
    );
    
    final daysInWeek = calendar.days.where((d) => d.weekNumber == _selectedWeek).toList();

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plannerVM.savedCalendars.length > 1) ...[
          DropdownButton<ContentCalendarModel>(
            value: calendar,
            dropdownColor: AppTheme.cardBackground,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.accent),
            underline: Container(),
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            items: plannerVM.savedCalendars.map((cal) {
              return DropdownMenuItem<ContentCalendarModel>(
                value: cal,
                child: Text('${cal.niche} Plan (${cal.frequency})'),
              );
            }).toList(),
            onChanged: (newCal) {
              if (newCal != null) {
                plannerVM.setActiveCalendar(newCal);
                setState(() {
                  _selectedDay = newCal.days.isNotEmpty ? newCal.days.first : null;
                  _selectedWeek = 1;
                });
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Weekly Navigation Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: calendar.weeks.map((week) {
              final isSelected = week.weekNumber == _selectedWeek;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('Week ${week.weekNumber}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedWeek = week.weekNumber;
                        _selectedDay = calendar.days.firstWhere(
                          (d) => d.weekNumber == week.weekNumber,
                          orElse: () => calendar.days.first,
                        );
                      });
                    }
                  },
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.cardBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Week Strategy Summary
        StrategyWeekCard(week: activeWeekPlan),
        const SizedBox(height: 24),

        // Grid of days in this week
        const Text(
          'Weekly Content Schedule',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: daysInWeek.length,
          itemBuilder: (context, index) {
            final day = daysInWeek[index];
            final isSelected = _selectedDay?.day == day.day;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primary.withOpacity(0.18) 
                      : AppTheme.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primary 
                        : Colors.white.withOpacity(0.06),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DAY',
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        
        TextButton.icon(
          onPressed: () {
            plannerVM.clearActiveCalendar();
            setState(() {
              _selectedDay = null;
            });
          },
          icon: const Icon(Icons.add_rounded, color: AppTheme.accent),
          label: const Text('Create New Plan', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    final detailsPanel = _selectedDay == null
        ? const Center(child: Text('Select a day to view details'))
        : DayDetailPanel(day: _selectedDay!);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: leftColumn),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: detailsPanel),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftColumn,
          const SizedBox(height: 24),
          detailsPanel,
        ],
      );
    }
  }
}

