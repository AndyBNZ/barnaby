// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'satellite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Satellite _$SatelliteFromJson(Map<String, dynamic> json) => Satellite(
  id: json['id'] as String,
  name: json['name'] as String,
  macAddress: json['macAddress'] as String?,
  ipAddress: json['ipAddress'] as String?,
  status: json['status'] as String,
  lastSeen: json['lastSeen'] == null
      ? null
      : DateTime.parse(json['lastSeen'] as String),
  config: json['config'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SatelliteToJson(Satellite instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'macAddress': instance.macAddress,
  'ipAddress': instance.ipAddress,
  'status': instance.status,
  'lastSeen': instance.lastSeen?.toIso8601String(),
  'config': instance.config,
  'createdAt': instance.createdAt.toIso8601String(),
};
