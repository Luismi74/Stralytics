import 'package:json_annotation/json_annotation.dart';

part 'processing_job.g.dart';

/// Status of a Strava activity processing job.
enum JobStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// Represents a background job for processing Strava activities.
/// Tracks progress and status in real-time via Supabase Realtime.
@JsonSerializable()
class ProcessingJob {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final JobStatus status;
  @JsonKey(name: 'total_activities')
  final int? totalActivities;
  @JsonKey(name: 'processed_activities')
  final int processedActivities;
  @JsonKey(name: 'current_activity_name')
  final String? currentActivityName;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  ProcessingJob({
    required this.id,
    required this.userId,
    required this.status,
    this.totalActivities,
    this.processedActivities = 0,
    this.currentActivityName,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  /// Calculates progress as a value between 0.0 and 1.0.
  double get progress {
    if (totalActivities == null || totalActivities! == 0) return 0.0;
    return processedActivities / totalActivities!;
  }

  /// Returns a percentage string (e.g., "75%").
  String get progressPercentage {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  /// Returns true if the job is in a terminal state (completed, failed, or cancelled).
  bool get isFinished =>
      status == JobStatus.completed ||
      status == JobStatus.failed ||
      status == JobStatus.cancelled;

  /// Returns true if the job is actively processing.
  bool get isActive =>
      status == JobStatus.pending || status == JobStatus.processing;

  factory ProcessingJob.fromJson(Map<String, dynamic> json) =>
      _$ProcessingJobFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingJobToJson(this);

  ProcessingJob copyWith({
    String? id,
    String? userId,
    JobStatus? status,
    int? totalActivities,
    int? processedActivities,
    String? currentActivityName,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ProcessingJob(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalActivities: totalActivities ?? this.totalActivities,
      processedActivities: processedActivities ?? this.processedActivities,
      currentActivityName: currentActivityName ?? this.currentActivityName,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
