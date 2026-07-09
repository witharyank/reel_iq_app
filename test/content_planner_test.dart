import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reeliq/features/dashboard/data/models/content_calendar_model.dart';
import 'package:reeliq/features/dashboard/data/services/planner_api_service.dart';
import 'package:reeliq/features/dashboard/presentation/viewmodels/planner_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Content Planner & Persistence Tests', () {
    late PlannerApiService apiService;

    setUp(() {
      apiService = PlannerApiService();
      SharedPreferences.setMockInitialValues({});
    });

    test('ContentCalendarDay and Model serialize and deserialize correctly', () {
      final day = ContentCalendarDay(
        day: 1,
        title: 'Flutter Test Day',
        idea: 'Build a unit test',
        hook: 'Watch this test pass',
        caption: 'Detailed testing caption',
        cta: 'Save for later',
        postingTime: '6:00 PM',
        difficulty: 'Easy',
        alternativeCTAs: [],
        alternativeCaptions: [],
        alternativeHooks: [],
        bRollSuggestions: '',
        cameraAngles: '',
        confidenceScore: 100,
        contentFormat: '',
        contentPillar: '',
        dailyObjective: '',
        editChecklist: [],
        editingInstructions: '',
        emotionTriggered: '',
        estimatedCreationTime: '',
        expectedEngagement: '',
        fullScript: '',
        funnelStage: '',
        hashtags: '',
        musicSuggestions: '',
        performanceReasoning: '',
        platform: '',
        preProductionChecklist: [],
        psychologyReason: '',
        psychologyUsed: '',
        reachEstimate: '',
        repurposeSuggestions: '',
        roiEstimate: '',
        shootChecklist: [],
        shotList: '',
        successMetrics: '',
        targetAudience: '',
        textOverlayTimeline: '',
        thumbnailIdea: '',
        thumbnailText: '',
        uploadChecklist: [],
        viralityPotential: 100,
        weekNumber: 1,
        whyThisWorks: '',
      );

      final calendar = ContentCalendarModel(
        id: 'test_id',
        niche: 'Coding',
        audience: 'Developers',
        goal: 'Learn testing',
        frequency: 'Daily',
        createdAt: DateTime.now(),
        days: [day],
        monthlyGoal: '',
        monthlyKPIs: [],
        platformDistribution: {},
        weeks: [],
        contentGapAnalysis: {},
        contentMixBreakdown: {},
      );

      final jsonMap = calendar.toJson();
      expect(jsonMap['id'], equals('test_id'));
      expect(jsonMap['niche'], equals('Coding'));
      expect(jsonMap['days'], isNotEmpty);
      expect(jsonMap['days'][0]['title'], equals('Flutter Test Day'));

      final parsed = ContentCalendarModel.fromJson(jsonMap, docId: 'test_id');
      expect(parsed.niche, equals('Coding'));
      expect(parsed.days.length, equals(1));
      expect(parsed.days[0].title, equals('Flutter Test Day'));
      expect(parsed.days[0].difficulty, equals('Easy'));
    });

    test('PlannerApiService generates 30 days fallback mock calendar correctly', () async {
      final calendar = await apiService.generateCalendar(
        niche: 'Cooking',
        audience: 'Beginners',
        goal: 'Cook a steak',
        frequency: '3 Reels per week',
      );

      expect(calendar, isNotNull);
      expect(calendar!.days.length, equals(30));
      expect(calendar.niche, equals('Cooking'));
      expect(calendar.audience, equals('Beginners'));
      expect(calendar.days.first.day, equals(1));
      expect(calendar.days.last.day, equals(30));
    });

    test('PlannerViewModel saves, loads, and deletes calendars locally', () async {
      final viewModel = PlannerViewModel(apiService);
      
      // Initially empty
      expect(viewModel.savedCalendars, isEmpty);
      expect(viewModel.activeCalendar, isNull);

      final calendar = ContentCalendarModel(
        id: 'cal_123',
        niche: 'Fitness',
        audience: 'Busy moms',
        goal: 'Stay fit',
        frequency: 'Daily',
        createdAt: DateTime.now(),
        monthlyGoal: '',
        monthlyKPIs: [],
        platformDistribution: {},
        weeks: [],
        contentGapAnalysis: {},
        contentMixBreakdown: {},
        days: [
          ContentCalendarDay(
            day: 1,
            title: 'Quick HIIT Workout',
            idea: 'Show 3 moves',
            hook: 'No time? Try this',
            caption: 'caption text',
            cta: 'Save this',
            postingTime: '8:00 AM',
            difficulty: 'Medium',
            alternativeCTAs: [],
            alternativeCaptions: [],
            alternativeHooks: [],
            bRollSuggestions: '',
            cameraAngles: '',
            confidenceScore: 100,
            contentFormat: '',
            contentPillar: '',
            dailyObjective: '',
            editChecklist: [],
            editingInstructions: '',
            emotionTriggered: '',
            estimatedCreationTime: '',
            expectedEngagement: '',
            fullScript: '',
            funnelStage: '',
            hashtags: '',
            musicSuggestions: '',
            performanceReasoning: '',
            platform: '',
            preProductionChecklist: [],
            psychologyReason: '',
            psychologyUsed: '',
            reachEstimate: '',
            repurposeSuggestions: '',
            roiEstimate: '',
            shootChecklist: [],
            shotList: '',
            successMetrics: '',
            targetAudience: '',
            textOverlayTimeline: '',
            thumbnailIdea: '',
            thumbnailText: '',
            uploadChecklist: [],
            viralityPotential: 100,
            weekNumber: 1,
            whyThisWorks: '',
          )
        ],
      );

      await viewModel.saveCalendarLocally(calendar);

      // Verify active and saved lists are updated
      expect(viewModel.savedCalendars.length, equals(1));
      expect(viewModel.activeCalendar, isNotNull);
      expect(viewModel.activeCalendar!.niche, equals('Fitness'));

      // Simulate app restart by reload from SharedPreferences mock
      final newViewModel = PlannerViewModel(apiService);
      await newViewModel.loadSavedCalendars();

      expect(newViewModel.savedCalendars.length, equals(1));
      expect(newViewModel.activeCalendar!.niche, equals('Fitness'));

      // Delete calendar
      await newViewModel.deleteCalendar('cal_123');
      expect(newViewModel.savedCalendars, isEmpty);
      expect(newViewModel.activeCalendar, isNull);
    });
  });
}
