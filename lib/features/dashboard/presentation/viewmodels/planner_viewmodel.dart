import 'dart:convert';
import 'package:flutter/material.dart';
// SharedPreferences no longer needed; using Firestore for persistence
import '../../data/models/content_calendar_model.dart';
import '../../data/services/planner_api_service.dart';
import '../../data/services/firestore_service.dart';

class PlannerViewModel extends ChangeNotifier {
  final PlannerApiService _apiService;
  final FirestoreCalendarService _firestoreService = FirestoreCalendarService();
  
  List<ContentCalendarModel> _savedCalendars = [];
  ContentCalendarModel? _activeCalendar;
  bool _isLoading = false;
  String? _errorMessage;

  PlannerViewModel(this._apiService) {
    loadSavedCalendars();
  }

  List<ContentCalendarModel> get savedCalendars => _savedCalendars;
  ContentCalendarModel? get activeCalendar => _activeCalendar;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedCalendars() async {
    try {
      final calendars = await _firestoreService.fetchCalendars();
      _savedCalendars = calendars;
      if (_savedCalendars.isNotEmpty && _activeCalendar == null) {
        _activeCalendar = _savedCalendars.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ReelIQ: Failed to load saved calendars from Firestore: $e');
    }
  }

  Future<void> saveCalendar(ContentCalendarModel calendar) async {
    try {
      // Save to Firestore
      await _firestoreService.saveCalendar(calendar);
      // Update local list
      final index = _savedCalendars.indexWhere((c) => c.id == calendar.id);
      if (index != -1) {
        _savedCalendars[index] = calendar;
      } else {
        _savedCalendars.insert(0, calendar);
      }
      _activeCalendar = calendar;
      notifyListeners();
    } catch (e) {
      debugPrint('ReelIQ: Failed to save calendar: $e');
    }
  }

  Future<void> deleteCalendar(String id) async {
    try {
      await _firestoreService.deleteCalendar(id);
      _savedCalendars.removeWhere((c) => c.id == id);
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
    _errorMessage = null;
    notifyListeners();

    try {
      final calendar = await _apiService.generateCalendar(
        niche: niche,
        audience: audience,
        goal: goal,
        frequency: frequency,
      );

      if (calendar != null) {
        await saveCalendar(calendar);
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
