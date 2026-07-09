import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/content_calendar_model.dart';
import '../../data/services/planner_api_service.dart';

class PlannerViewModel extends ChangeNotifier {
  final PlannerApiService _apiService;
  
  List<ContentCalendarModel> _savedCalendars = [];
  ContentCalendarModel? _activeCalendar;
  bool _isLoading = false;
  String _loadingStage = '';
  String? _errorMessage;

  PlannerViewModel(this._apiService) {
    loadSavedCalendars();
  }

  List<ContentCalendarModel> get savedCalendars => _savedCalendars;
  ContentCalendarModel? get activeCalendar => _activeCalendar;
  bool get isLoading => _isLoading;
  String get loadingStage => _loadingStage;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedCalendars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarData = prefs.getStringList('reeliq_saved_calendars') ?? [];
      
      _savedCalendars = calendarData
          .map((item) => ContentCalendarModel.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
      if (_savedCalendars.isNotEmpty && _activeCalendar == null) {
        _activeCalendar = _savedCalendars.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ReelIQ: Failed to load saved calendars: $e');
    }
  }

  Future<void> saveCalendarLocally(ContentCalendarModel calendar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if calendar already exists
      final index = _savedCalendars.indexWhere((c) => c.id == calendar.id);
      if (index != -1) {
        _savedCalendars[index] = calendar;
      } else {
        _savedCalendars.insert(0, calendar);
      }
      
      final stringList = _savedCalendars.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList('reeliq_saved_calendars', stringList);
      _activeCalendar = calendar;
      notifyListeners();
    } catch (e) {
      debugPrint('ReelIQ: Failed to save calendar: $e');
    }
  }

  Future<void> deleteCalendar(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedCalendars.removeWhere((c) => c.id == id);
      
      final stringList = _savedCalendars.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList('reeliq_saved_calendars', stringList);
      
      if (_activeCalendar?.id == id) {
        _activeCalendar = _savedCalendars.isNotEmpty ? _savedCalendars.first : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ReelIQ: Failed to delete calendar: $e');
    }
  }

  Future<ContentCalendarModel?> generateNewCalendar({
    required String niche,
    required String audience,
    required String goal,
    required String frequency,
  }) async {
    _isLoading = true;
    _loadingStage = 'Initializing strategy engine...';
    _errorMessage = null;
    notifyListeners();

    try {
      final calendar = await _apiService.generateCalendar(
        niche: niche,
        audience: audience,
        goal: goal,
        frequency: frequency,
        onProgress: (stage) {
          _loadingStage = stage;
          notifyListeners();
        },
      );

      if (calendar != null) {
        await saveCalendarLocally(calendar);
        return calendar;
      } else {
        _errorMessage = 'Could not generate calendar. Please try again.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  void setActiveCalendar(ContentCalendarModel calendar) {
    _activeCalendar = calendar;
    notifyListeners();
  }

  void clearActiveCalendar() {
    _activeCalendar = null;
    notifyListeners();
  }
}
