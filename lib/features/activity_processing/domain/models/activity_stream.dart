import 'package:json_annotation/json_annotation.dart';

part 'activity_stream.g.dart';

/// Types of activity streams available from Strava.
enum StreamType {
  @JsonValue('time')
  time,
  @JsonValue('latlng')
  latlng,
  @JsonValue('distance')
  distance,
  @JsonValue('altitude')
  altitude,
  @JsonValue('heartrate')
  heartrate,
  @JsonValue('watts')
  watts,
  @JsonValue('cadence')
  cadence,
  @JsonValue('temp')
  temp,
}

/// Represents a single stream of data for an activity (GPS, heart rate, power, etc.).
@JsonSerializable()
class ActivityStream {
  @JsonKey(name: 'activity_id')
  final int activityId;
  @JsonKey(name: 'stream_type')
  final StreamType streamType;
  final List<dynamic> data;

  ActivityStream({
    required this.activityId,
    required this.streamType,
    required this.data,
  });

  /// Returns the number of data points in the stream.
  int get length => data.length;

  /// Returns true if this stream has data.
  bool get hasData => data.isNotEmpty;

  factory ActivityStream.fromJson(Map<String, dynamic> json) =>
      _$ActivityStreamFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityStreamToJson(this);
}
