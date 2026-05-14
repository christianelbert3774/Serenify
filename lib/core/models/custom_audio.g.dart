// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_audio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomAudioAdapter extends TypeAdapter<CustomAudio> {
  @override
  final int typeId = 1;

  @override
  CustomAudio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomAudio(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String,
      importedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomAudio obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.importedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomAudioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
