import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/custom_audio.dart';

class CustomAudioRepository {
  static const _boxName = 'custom_audio';
  static const _folder = 'custom_audio';

  static Future<void> init() async {
    Hive.registerAdapter(CustomAudioAdapter());
    await Hive.openBox<CustomAudio>(_boxName);
  }

  static Box<CustomAudio> get _box => Hive.box<CustomAudio>(_boxName);

  /// Import file from source path to app's private storage.
  /// Returns the saved [CustomAudio] entry.
  static Future<CustomAudio> importFile(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = p.extension(sourcePath);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final destPath = '${dir.path}/$id$ext';
    await File(sourcePath).copy(destPath);

    final name = p.basenameWithoutExtension(sourcePath);
    final audio = CustomAudio(id: id, name: name, filePath: destPath);
    await _box.add(audio);
    return audio;
  }

  /// Get all imported custom audio files, newest first.
  static List<CustomAudio> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  /// Delete a custom audio entry and its file from storage.
  static Future<void> delete(CustomAudio audio) async {
    final file = File(audio.filePath);
    if (await file.exists()) await file.delete();
    await audio.delete();
  }
}
