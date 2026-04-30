// GENERATED CODE — hand-written to avoid build_runner dependency

part of 'preset.dart';

class PresetAdapter extends TypeAdapter<Preset> {
  @override
  final int typeId = 0;

  @override
  Preset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Preset(
      name: fields[0] as String,
      noiseType: fields[1] as String?,
      noiseVolume: fields[2] as double,
      activeSoundscapes: (fields[3] as Map).cast<String, double>(),
      binauralEnabled: fields[4] as bool,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Preset obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.noiseType)
      ..writeByte(2)
      ..write(obj.noiseVolume)
      ..writeByte(3)
      ..write(obj.activeSoundscapes)
      ..writeByte(4)
      ..write(obj.binauralEnabled)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
