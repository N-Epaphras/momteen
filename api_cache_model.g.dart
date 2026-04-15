// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_cache_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiCacheModelAdapter extends TypeAdapter<ApiCacheModel> {
  @override
  final int typeId = 3;

  @override
  ApiCacheModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiCacheModel(
      cacheKey: fields[0] as String,
      response: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ApiCacheModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.cacheKey)
      ..writeByte(1)
      ..write(obj.response)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCacheModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
