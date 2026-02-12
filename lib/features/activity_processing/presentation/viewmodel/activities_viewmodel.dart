import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/activity_repository.dart';
import '../../domain/models/strava_activity.dart';

/// ViewModel for managing the activities list.
class ActivitiesViewModel extends ChangeNotifier {
  final ActivityRepository _repository;

  List<StravaActivity> _activities = [];
  List<StravaActivity> get activities => _activities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ActivitiesViewModel(this._repository) {
    loadActivities();
  }

  /// Loads all activities from Supabase.
  Future<void> loadActivities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activities = await _repository.getAllActivities();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes an activity.
  Future<void> deleteActivity(int activityId) async {
    try {
      await _repository.deleteActivity(activityId);
      _activities.removeWhere((a) => a.activityId == activityId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

/// Riverpod provider for ActivitiesViewModel.
final activitiesViewModelProvider = ChangeNotifierProvider((ref) {
  return ActivitiesViewModel(ActivityRepository());
});
