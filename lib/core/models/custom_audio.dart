import 'package:hive/hive.dart';

part 'custom_audio.g.dart';

@HiveType(typeId: 1)
class CustomAudio extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DateTime importedAt;

  CustomAudio({
    required this.id,
    required this.name,
    required this.filePath,
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now();
}
