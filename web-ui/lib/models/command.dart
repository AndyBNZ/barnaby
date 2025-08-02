import 'package:json_annotation/json_annotation.dart';

part 'command.g.dart';

@JsonSerializable()
class CommandHistory {
  final String id;
  final String? userId;
  final String? satelliteId;
  final String commandText;
  final String? intent;
  final String? response;
  final double? confidence;
  final int? processingTimeMs;
  final DateTime createdAt;

  CommandHistory({
    required this.id,
    this.userId,
    this.satelliteId,
    required this.commandText,
    this.intent,
    this.response,
    this.confidence,
    this.processingTimeMs,
    required this.createdAt,
  });

  factory CommandHistory.fromJson(Map<String, dynamic> json) => _$CommandHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$CommandHistoryToJson(this);
}

@JsonSerializable()
class ProcessVoiceRequest {
  @JsonKey(name: 'audio_data')
  final String audioData;
  @JsonKey(name: 'satellite_id')
  final String? satelliteId;

  ProcessVoiceRequest({required this.audioData, this.satelliteId});

  factory ProcessVoiceRequest.fromJson(Map<String, dynamic> json) => _$ProcessVoiceRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ProcessVoiceRequestToJson(this);
}

@JsonSerializable()
class ProcessVoiceResponse {
  final String transcription;
  final String intent;
  final String response;
  @JsonKey(name: 'audio_response')
  final String audioResponse;

  ProcessVoiceResponse({
    required this.transcription,
    required this.intent,
    required this.response,
    required this.audioResponse,
  });

  factory ProcessVoiceResponse.fromJson(Map<String, dynamic> json) => _$ProcessVoiceResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProcessVoiceResponseToJson(this);
}