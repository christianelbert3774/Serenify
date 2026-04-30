import 'package:hive/hive.dart';
import '../models/preset.dart';

/// Repository untuk CRUD preset via Hive
class PresetRepository {
  static const String _boxName = 'presets';

  /// Buka Hive box (panggil sekali saat app start)
  static Future<void> init() async {
    Hive.registerAdapter(PresetAdapter());
    await Hive.openBox<Preset>(_boxName);
  }

  static Box<Preset> get _box => Hive.box<Preset>(_boxName);

  /// Simpan preset baru
  static Future<int> savePreset(Preset preset) async {
    return await _box.add(preset);
  }

  /// Ambil semua preset (terbaru di atas)
  static List<Preset> getPresets() {
    final presets = _box.values.toList();
    presets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return presets;
  }

  /// Hapus preset berdasarkan key
  static Future<void> deletePreset(Preset preset) async {
    await preset.delete();
  }
}
