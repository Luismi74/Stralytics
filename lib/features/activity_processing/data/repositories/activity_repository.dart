import '../../domain/models/strava_activity.dart';
import '../../domain/models/activity_stream.dart';
import '../../../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for accessing processed Strava activities and streams.
class ActivityRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Fetches all activities for the current user.
  ///
  /// Activities are ordered by start date (newest first).
  /// Returns an empty list if no activities are found or user is not authenticated.
  Future<List<StravaActivity>> getAllActivities() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('activities')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      return (response as List)
          .map((json) => StravaActivity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  /// Fetches a single activity by ID.
  ///
  /// Returns null if the activity is not found or doesn't belong to the current user.
  Future<StravaActivity?> getActivity(int activityId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('activities')
          .select()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return StravaActivity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch activity: $e');
    }
  }

  /// Fetches all streams for a specific activity.
  ///
  /// Returns an empty list if no streams are found.
  Future<List<ActivityStream>> getActivityStreams(int activityId) async {
    try {
      final response = await _client
          .from('activity_streams')
          .select()
          .eq('activity_id', activityId);

      return (response as List)
          .map((json) => ActivityStream.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch activity streams: $e');
    }
  }

  /// Fetches a specific stream type for an activity.
  ///
  /// Returns null if the stream is not found.
  Future<ActivityStream?> getActivityStream(
    int activityId,
    StreamType streamType,
  ) async {
    try {
      final response = await _client
          .from('activity_streams')
          .select()
          .eq('activity_id', activityId)
          .eq('stream_type', streamType.name)
          .maybeSingle();

      if (response == null) return null;
      return ActivityStream.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch activity stream: $e');
    }
  }

  /// Watches all activities for real-time updates.
  ///
  /// This stream will emit a new list whenever activities are added, updated, or deleted.
  Stream<List<StravaActivity>> watchActivities() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('activities')
        .stream(primaryKey: ['activity_id'])
        .eq('user_id', userId)
        .order('start_date', ascending: false)
        .map((data) =>
            data.map((json) => StravaActivity.fromJson(json)).toList());
  }

  /// Deletes an activity and all associated streams.
  ///
  /// Note: This uses CASCADE DELETE, so streams will be automatically removed.
  Future<void> deleteActivity(int activityId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('activities')
          .delete()
          .eq('activity_id', activityId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }
}
