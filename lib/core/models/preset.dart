import 'package:hive/hive.dart';

part 'preset.g.dart';

@HiveType(typeId: 0)
class Preset extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String? noiseType; // 'white', 'pink', 'brown', or null

  @HiveField(2)
  final double noiseVolume;

  @HiveField(3)
  final Map<String, double> activeSoundscapes; // id → volume

  @HiveField(4)
  final bool binauralEnabled;

  @HiveField(5)
  final DateTime createdAt;

  Preset({
    required this.name,
    this.noiseType,
    this.noiseVolume = 0.7,
    required this.activeSoundscapes,
    this.binauralEnabled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
