// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandHistory _$CommandHistoryFromJson(Map<String, dynamic> json) =>
    CommandHistory(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      satelliteId: json['satelliteId'] as String?,
      commandText: json['commandText'] as String,
      intent: json['intent'] as String?,
      response: json['response'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CommandHistoryToJson(CommandHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'satelliteId': instance.satelliteId,
      'commandText': instance.commandText,
      'intent': instance.intent,
      'response': instance.response,
      'confidence': instance.confidence,
      'processingTimeMs': instance.processingTimeMs,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ProcessVoiceRequest _$ProcessVoiceRequestFromJson(Map<String, dynamic> json) =>
    ProcessVoiceRequest(
      audioData: json['audio_data'] as String,
      satelliteId: json['satellite_id'] as String?,
    );

Map<String, dynamic> _$ProcessVoiceRequestToJson(
  ProcessVoiceRequest instance,
) => <String, dynamic>{
  'audio_data': instance.audioData,
  'satellite_id': instance.satelliteId,
};

ProcessVoiceResponse _$ProcessVoiceResponseFromJson(
  Map<String, dynamic> json,
) => ProcessVoiceResponse(
  transcription: json['transcription'] as String,
  intent: json['intent'] as String,
  response: json['response'] as String,
  audioResponse: json['audio_response'] as String,
);

Map<String, dynamic> _$ProcessVoiceResponseToJson(
  ProcessVoiceResponse instance,
) => <String, dynamic>{
  'transcription': instance.transcription,
  'intent': instance.intent,
  'response': instance.response,
  'audio_response': instance.audioResponse,
};
