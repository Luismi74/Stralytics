import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/processing_job.dart';
import '../../../../core/services/supabase_service.dart';

/// Repository for managing activity processing jobs.
/// Handles job submission, progress monitoring, and cancellation.
class ProcessingRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Submits a new processing job to the Supabase Edge Function.
  ///
  /// Returns the job ID for tracking progress.
  /// Throws an exception if the user is not authenticated or if submission fails.
  Future<String> submitJob(String stravaAccessToken) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }

    try {
      // Insert job record with pending status
      final response = await _client
          .from('processing_jobs')
          .insert({
            'user_id': userId,
            'status': 'pending',
            'strava_access_token': stravaAccessToken,
          })
          .select()
          .single();

      final jobId = response['id'] as String;

      // Invoke Edge Function to start processing
      final functionResponse = await _client.functions.invoke(
        'process_strava_activities',
        body: {
          'jobId': jobId,
          'accessToken': stravaAccessToken,
        },
      );

      // Check for errors in function response
      if (functionResponse.status != 200) {
        throw Exception('Edge Function error: ${functionResponse.data}');
      }

      return jobId;
    } catch (e) {
      throw Exception('Failed to submit processing job: $e');
    }
  }

  /// Watches a job's progress in real-time using Supabase Realtime.
  ///
  /// Returns a stream that emits updated [ProcessingJob] objects as the job progresses.
  /// The stream will emit whenever the job status, progress, or current activity changes.
  Stream<ProcessingJob> watchJob(String jobId) {
    return _client
        .from('processing_jobs')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('Job not found: $jobId');
          }
          return ProcessingJob.fromJson(data.first);
        });
  }

  /// Fetches a single job by ID.
  ///
  /// Returns null if the job is not found.
  Future<ProcessingJob?> getJob(String jobId) async {
    try {
      final response = await _client
          .from('processing_jobs')
          .select()
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;
      return ProcessingJob.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch job: $e');
    }
  }

  /// Fetches all processing jobs for the current user.
  ///
  /// Jobs are ordered by creation date (newest first).
  Future<List<ProcessingJob>> getAllJobs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('processing_jobs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProcessingJob.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  /// Cancels a processing job.
  ///
  /// This sets the job status to 'cancelled', which should signal the Edge Function
  /// to stop processing (if it checks for cancellation).
  Future<void> cancelJob(String jobId) async {
    try {
      await _client.from('processing_jobs').update({
        'status': 'cancelled',
      }).eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to cancel job: $e');
    }
  }

  /// Deletes a job from the database.
  ///
  /// Note: This will NOT stop a currently running Edge Function.
  /// Use [cancelJob] to signal cancellation first.
  Future<void> deleteJob(String jobId) async {
    try {
      await _client.from('processing_jobs').delete().eq('id', jobId);
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }
}
