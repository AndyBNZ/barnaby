import 'package:json_annotation/json_annotation.dart';

part 'satellite.g.dart';

@JsonSerializable()
class Satellite {
  final String id;
  final String name;
  final String? macAddress;
  final String? ipAddress;
  final String status;
  final DateTime? lastSeen;
  final String? config;
  final DateTime createdAt;

  Satellite({
    required this.id,
    required this.name,
    this.macAddress,
    this.ipAddress,
    required this.status,
    this.lastSeen,
    this.config,
    required this.createdAt,
  });

  factory Satellite.fromJson(Map<String, dynamic> json) => _$SatelliteFromJson(json);
  Map<String, dynamic> toJson() => _$SatelliteToJson(this);

  bool get isOnline => status == 'online';
  bool get isOffline => status == 'offline';
}