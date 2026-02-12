import 'package:json_annotation/json_annotation.dart';

part 'strava_activity.g.dart';

/// Represents a processed Strava activity stored in Supabase.
@JsonSerializable()
class StravaActivity {
  @JsonKey(name: 'activity_id')
  final int activityId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  final double? distance;
  @JsonKey(name: 'moving_time')
  final int? movingTime;
  @JsonKey(name: 'elapsed_time')
  final int? elapsedTime;
  @JsonKey(name: 'total_elevation_gain')
  final double? totalElevationGain;
  @JsonKey(name: 'sport_type')
  final String? sportType;
  @JsonKey(name: 'raw_data')
  final Map<String, dynamic> rawData;
  @JsonKey(name: 'image_urls')
  final List<String>? imageUrls;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  StravaActivity({
    required this.activityId,
    required this.userId,
    required this.name,
    required this.startDate,
    this.distance,
    this.movingTime,
    this.elapsedTime,
    this.totalElevationGain,
    this.sportType,
    required this.rawData,
    this.imageUrls,
    required this.createdAt,
  });

  /// Formatted distance in kilometers.
  String get distanceKm {
    if (distance == null) return 'N/A';
    return '${(distance! / 1000).toStringAsFixed(2)} km';
  }

  /// Formatted moving time as HH:MM:SS.
  String get formattedMovingTime {
    if (movingTime == null) return 'N/A';
    final duration = Duration(seconds: movingTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory StravaActivity.fromJson(Map<String, dynamic> json) =>
      _$StravaActivityFromJson(json);

  Map<String, dynamic> toJson() => _$StravaActivityToJson(this);
}
