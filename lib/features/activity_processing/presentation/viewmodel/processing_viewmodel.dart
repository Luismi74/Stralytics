import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/processing_repository.dart';
import '../../domain/models/processing_job.dart';
import 'dart:async';

/// ViewModel for managing activity processing job lifecycle.
class ProcessingViewModel extends ChangeNotifier {
  final ProcessingRepository _repository;

  ProcessingJob? _currentJob;
  ProcessingJob? get currentJob => _currentJob;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  StreamSubscription<ProcessingJob>? _jobSubscription;

  ProcessingViewModel(this._repository);

  /// Starts a new processing job with the given Strava access token.
  ///
  /// This will:
  /// 1. Submit the job to Supabase Edge Function
  /// 2. Subscribe to real-time progress updates
  /// 3. Notify listeners as progress changes
  Future<void> startProcessing(String accessToken) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      // Submit job
      final jobId = await _repository.submitJob(accessToken);

      // Subscribe to real-time updates
      await _jobSubscription?.cancel();
      _jobSubscription = _repository.watchJob(jobId).listen(
        (job) {
          _currentJob = job;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Cancels the current processing job.
  Future<void> cancelProcessing() async {
    if (_currentJob == null) return;

    try {
      await _repository.cancelJob(_currentJob!.id);
      // The real-time subscription will automatically update the job status
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Loads an existing job by ID (useful for resuming/viewing).
  Future<void> loadJob(String jobId) async {
    try {
      final job = await _repository.getJob(jobId);
      if (job != null) {
        _currentJob = job;

        // Subscribe to updates if job is still active
        if (job.isActive) {
          await _jobSubscription?.cancel();
          _jobSubscription = _repository.watchJob(jobId).listen(
            (updatedJob) {
              _currentJob = updatedJob;
              notifyListeners();
            },
            onError: (error) {
              _error = error.toString();
              notifyListeners();
            },
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clears the current job and resets the state.
  void clearJob() {
    _currentJob = null;
    _error = null;
    _jobSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for ProcessingViewModel.
final processingViewModelProvider = ChangeNotifierProvider((ref) {
  return ProcessingViewModel(ProcessingRepository());
});
